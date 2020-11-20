output "lb_public_dns" {
  value = aws_lb.aik_lb_est10.dns_name
}
