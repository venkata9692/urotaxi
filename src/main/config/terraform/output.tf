output "urotaxi_public_ip" {
    value = aws_instance.urotaxijumpbox.public_ip  
}
output "urotaxi_db_endpoint" {
    value = aws_db_instance.urotaxidb.endpoint  
}