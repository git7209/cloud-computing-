resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  
  # Default VPC is used if vpc_security_group_ids or subnet_id is not specified, 
  # or we can explicitly specify a subnet in the default VPC.
  # Since requirements say "Default VPC에 배포되어야 하며", purely omitting subnet_id usually picks a default subnet.
  
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name
  
  disable_api_termination = true # EC2 termination protection : 활성화

  tags = {
    Name = "automation-bastion"
  }

  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /home/ec2-user/ec2-automation

    # Create delete_old_instance.sh
    cat <<'SCRIPT' > /home/ec2-user/ec2-automation/delete_old_instance.sh
    #!/bin/bash
    # Project=skills2022 태그가 부여된 모든 인스턴스를 삭제합니다.
    INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=skills2022" "Name=instance-state-name,Values=running,stopped" --query "Reservations[].Instances[].InstanceId" --output text)

    if [ -n "$INSTANCE_IDS" ]; then
      aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
      echo "Terminated instances: $INSTANCE_IDS"
    else
      echo "No instances found with tag Project=skills2022"
    fi
    SCRIPT

    # Create delete_all_instance.sh
    cat <<'SCRIPT' > /home/ec2-user/ec2-automation/delete_all_instance.sh
    #!/bin/bash
    # Bastion을 제외한 계정에 존재하는 모든 인스턴스를 삭제합니다.
    # Get the instance ID of this Bastion host
    MY_INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

    # Get all running or stopped instances
    ALL_IDS=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running,stopped" --query "Reservations[].Instances[].InstanceId" --output text)
    
    # Filter out my instance ID
    TARGET_IDS=""
    for id in $ALL_IDS; do
      if [ "$id" != "$MY_INSTANCE_ID" ]; then
        TARGET_IDS="$TARGET_IDS $id"
      fi
    done

    if [ -n "$TARGET_IDS" ]; then
      aws ec2 terminate-instances --instance-ids $TARGET_IDS
      echo "Terminated instances: $TARGET_IDS"
    else
      echo "No other instances found to terminate."
    fi
    SCRIPT

    # Set permissions
    chmod +x /home/ec2-user/ec2-automation/*.sh
    chown -R ec2-user:ec2-user /home/ec2-user/ec2-automation
  EOF
}
