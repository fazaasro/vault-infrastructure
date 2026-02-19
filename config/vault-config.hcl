ui = true

# "listener" is the socket that Vault uses for communication
listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = true
}

# "storage" is where Vault stores data
storage "file" {
  path = "/vault/data"
}

# "api_addr" is the full address of the API endpoint
api_addr = "http://0.0.0.0:8200"

# "cluster_addr" is the full address of the cluster endpoint
cluster_addr = "https://0.0.0.0:8201"

# Maximum number of concurrent requests
max_lease_ttl = "87600h"
default_lease_ttl = "87600h"

# Disable mlock for container environment
disable_mlock = true
