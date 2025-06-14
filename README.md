# topology-02

We implemented the topology shown below:  
![image](https://github.com/user-attachments/assets/ae3f4298-d1d9-41e6-b1d1-df3025fc6f99)

We will now set up the environment for the topology.

> **Note**: Make sure you have cloned this repository at the **same level and location** as the `free5gc-compose` directory.

---

## Set up the environment

```bash
# Navigate to the config folder
cd topology-02/config 

# Copy its contents into the original free5gc-compose config folder
cp -r . ../../free5gc-compose/config

# Copy the Docker Compose file
cd ..
cp docker-compose-build-top02.yaml ../free5gc-compose

# Replace UPF and UERANSIM configurations
mv -r ueransim nf_upf ../free5gc-compose

# Copy test scripts and make them executable
cp -r test-scripts ../free5gc-compose
find ../free5gc-compose/test-scripts -type f -name "*.sh" -exec chmod +x {} \;
```

## Test the topology
Make sure you are in the free5gc-compose folder. Use sudo if necessary.
```bash
cd ../free5gc-compose/test-scripts

# Launch the environment
./topology-02-env.sh

# Create 6 UEs using the web interface
./addusers.sh

# Register the UEs
./ue_registration.sh

# Test connectivity
# Parameters:
#   1st: gNB instance (ueransim-1 = gNB 01, ueransim-2 = gNB 02, ueransim-3 = gNB 03)
#   2nd: UE interface (uesimtun0 = UE 01, uesimtun1 = UE 02)
#   3rd: DNN IP (e.g., 172.17.0.1 or 10.10.0.1)

./test_conn_top02.sh ueransim-1 uesimtun0 172.17.0.1
```

> The results will be on test-script/output
