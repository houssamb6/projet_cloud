# ============================================
# SECURITY GROUPS — Pare-feux par couche
# ============================================
#
# Architecture des flux autorisés :
#
#   Internet → ALB (port 80)
#   ALB → Backend EC2 (port API)
#   Backend EC2 → RDS (port 3306/5432)
#   Internet → Frontend EC2 (port 80)
#   Votre IP → Frontend EC2 (port 22, SSH)
#
# Aucune autre communication n'est autorisée.
# ============================================

# ════════════════════════════════════════
# SG 1 : ALB — reçoit le trafic internet
# ════════════════════════════════════════
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "ALB : accepte HTTP depuis internet uniquement"
  vpc_id      = aws_vpc.main.id

  # HTTP depuis n'importe où sur internet
  ingress {
    description = "HTTP entrant"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # L'ALB peut sortir vers les instances du Target Group
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-alb"
    Project = var.project_name
  }
}

# ════════════════════════════════════════
# SG 2 : Backend EC2 — reçoit trafic de l'ALB seulement
# ════════════════════════════════════════
# ⚠️ Jamais depuis internet directement !
resource "aws_security_group" "backend" {
  name        = "${var.project_name}-sg-backend"
  description = "Backend EC2 : trafic entrant uniquement depuis le SG de l'ALB"
  vpc_id      = aws_vpc.main.id

  # Accepte uniquement les connexions venant du Security Group de l'ALB
  # (pas depuis 0.0.0.0/0 — même si le port est le bon !)
  ingress {
    description     = "Trafic API depuis l'ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # ← référence au SG ALB
  }

  # Sortie libre pour git clone, npm install, etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-backend"
    Project = var.project_name
  }
}

# ════════════════════════════════════════
# SG 3 : RDS — reçoit trafic du backend seulement
# ════════════════════════════════════════
# ⚠️ Jamais depuis internet, jamais depuis votre ordinateur !
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "RDS : trafic entrant uniquement depuis le SG backend"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL depuis le backend"
    from_port       = 3306     # Changez en 5432 si vous utilisez PostgreSQL
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]  # ← backend seulement
    # ⚠️ JAMAIS cidr_blocks = ["0.0.0.0/0"] ici !
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-rds"
    Project = var.project_name
  }
}

# ════════════════════════════════════════
# SG 4 : Frontend EC2 — HTTP public + SSH limité
# ════════════════════════════════════════
resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-sg-frontend"
  description = "Frontend EC2 : HTTP public + SSH depuis votre IP seulement"
  vpc_id      = aws_vpc.main.id

  # HTTP depuis n'importe où (les visiteurs accèdent au site)
  ingress {
    description = "HTTP public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH depuis votre IP uniquement (débogage)
  ingress {
    description = "SSH depuis mon IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]   # ← uniquement votre IP, pas 0.0.0.0/0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg-frontend"
    Project = var.project_name
  }
}