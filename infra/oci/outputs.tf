output "server_public_ip" {
  description = "Public address of the server node (HTTP/HTTPS ingress and SSH)."
  value       = oci_core_instance.server.public_ip
}

output "agent_public_ips" {
  description = "Public addresses of the agent nodes."
  value       = oci_core_instance.agent[*].public_ip
}

output "ssh" {
  description = "Log in to the server."
  value       = "ssh ubuntu@${oci_core_instance.server.public_ip}"
}

output "api_tunnel" {
  description = "The Kubernetes API is not exposed. Open a tunnel, then use the fetched kubeconfig."
  value       = "ssh -N -L 6443:127.0.0.1:6443 ubuntu@${oci_core_instance.server.public_ip}"
}
