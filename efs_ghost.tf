resource "aws_efs_file_system" "ghost" {
    performance_mode = "generalPurpose"
    throughput_mode = "bursting"
}

resource "aws_efs_mount_target" "ghost" {
    # TODO: private subnet (no NAT)
    for_each = aws_subnet.public

    file_system_id = aws_efs_file_system.ghost.id
    subnet_id = each.value.id
    security_groups = [aws_security_group.efs_ghost.id]
}

resource "aws_security_group" "efs_ghost" {
    vpc_id = aws_vpc.default.id
    name = "efs_ghost"
}

resource "aws_security_group_rule" "efs_ghost_ingress" {
    security_group_id = aws_security_group.efs_ghost.id

    type              = "ingress"
    from_port         = 2049
    to_port           = 2049
    protocol          = "tcp"

    source_security_group_id = aws_security_group.ghost.id
}