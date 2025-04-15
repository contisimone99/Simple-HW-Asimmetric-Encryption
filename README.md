# Simple Asymmetric Encryption (SAE) System

This repository contains an implementation of a Simple Asymmetric Encryption (SAE) system in SystemVerilog and Python. The system uses a basic asymmetric encryption algorithm where two parties can securely communicate by exchanging public keys while keeping their private keys secret.

> **Authors**: Simone Conti and Gabriele Galli  
> **Course Project**: Hardware and Embedded Security

## System Overview

The SAE system implements a basic asymmetric encryption scheme using modular arithmetic with prime number p = 223. The system supports three main operations:

1. **Key-pair Generation**: Generates a public key from a secret key using the formula `PK = p - SK`
2. **Encryption**: Encrypts plaintext using the formula `C[i] = (P[i] + PK) mod p`
3. **Decryption**: Decrypts ciphertext using the formula `P[i] = (C[i] + SK) mod p`

## Repository Structure

```
.
├── db/              # Main SAE module in SystemVerilog
│   └── SAE.sv
├── model/           # Python implementation of the module
│   └── script.py
├── tb/              # Testbench in SystemVerilog
│   └── SAE_tb.sv
├── modelsim/        
│   ├── build.py
│   ├── clean.py
│   ├── tv/
│   │   ├── dictionary.txt
│   │   ├── Walter_SK.txt, Jesse_SK.txt
│   │   ├── Walter_PK.txt, Jesse_PK.txt
│   │   ├── Walter_PT.txt, Jesse_PT.txt
│   │   ├── Walter_CT.txt, Jesse_CT.txt
│   └── wave/
│       └── wave.do
├── quartus/         
│   ├── build.py
│   ├── clean.py
│   ├── constr/
│   │   ├── automatic_virtual_pin.tcl
│   │   └── time_constr_template.sdc
│   └── quartus.build
├── doc/
    ├── project_rules.pdf
    ├── project_specs.pdf
    ├── Relazione_Conti_Galli.pdf
    └── work_env_guide.pdf           
├── LICENSE
└── README.md
```

## Module Description

### SAE.sv

The SystemVerilog implementation consists of the following modules:

- **pubkey_gen_mod**: Generates a public key from a secret key
- **encryption_mod**: Encrypts plaintext using a public key
- **decryption_mod**: Decrypts ciphertext using a secret key
- **SAE**: Top-level module that integrates the above submodules

The SAE module supports three operation modes:
- `2'b01`: Key-pair generation
- `2'b10`: Encryption
- `2'b11`: Decryption

### script.py

The Python script provides a reference implementation of the SAE system and is used to generate test vectors for verification. It includes functions for:

- Key generation
- Encryption
- Decryption

### SAE_tb.sv

The testbench simulates communication between two parties (Walter and Jesse) who exchange encrypted messages. The test flow includes:

1. Both parties generate their key pairs
2. Walter encrypts a message using Jesse's public key and sends it to Jesse
3. Jesse decrypts the message using his secret key
4. Jesse encrypts a message using Walter's public key and sends it to Walter
5. Walter decrypts the message using his secret key
6. The testbench verifies that the decrypted messages match the original plaintexts

## Implementation Details

### Encryption Algorithm

This implementation uses a simple modular addition scheme:

- Key-pair generation: `PK = p - SK` where p = 223
- Encryption: `C[i] = (P[i] + PK) mod p`
- Decryption: `P[i] = (C[i] + SK) mod p`

### Secret Key Constraints

Valid secret keys must be in the range of 1 to 222 (inclusive). The system checks for invalid secret keys and reports errors.

## How to Use

### Simulation

To run the simulation:

1. Ensure you have ModelSim or another SystemVerilog simulator installed
2. Run the Python script to generate test vectors:
   ```
   cd model
   python script.py
   ```
3. Run the testbench in your simulator

### Hardware Implementation

The SAE module is synthesizable and can be implemented on FPGA or ASIC targets. Constraints and build scripts for Quartus are included under the quartus/ folder.

## Example Communication Flow

1. Both parties (Walter and Jesse) generate their key pairs:
   - Walter: Secret Key → Public Key
   - Jesse: Secret Key → Public Key

2. Walter encrypts a message using Jesse's public key
3. Jesse receives the ciphertext and decrypts it using his secret key
4. Jesse encrypts a message using Walter's public key
5. Walter receives the ciphertext and decrypts it using his secret key

## Security Considerations

Note that this implementation is for educational purposes and demonstrates basic concepts of asymmetric encryption. The actual encryption algorithm used is very simple and not secure for real-world applications. For production systems, use established encryption standards like RSA, ECC, or other well-vetted algorithms.

## License
This project is licensed under the terms of the [LICENSE](./LICENSE) file.
