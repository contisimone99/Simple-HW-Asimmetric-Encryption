import os
import secrets
p = 223

def encrypt(plaintext:str, key:int):
    #𝐶[𝑖]= (𝑃[𝑖] + 𝑃𝐾) 𝑚𝑜𝑑 p
    ciphertext = []        
    for pt in plaintext:
        enc = (ord(pt) + key) % p
        ciphertext.append(chr(enc))
    return "".join(ciphertext)

def decrypt(ciphertext:str, key:int):
    #𝑃[𝑖]= (𝐶[𝑖] + 𝑆𝐾) 𝑚𝑜𝑑 𝑝
    plaintext = []
    for c in ciphertext:
        dec = (ord(c) + key) % p
        plaintext.append(chr(dec))
    return "".join(plaintext)

def key_generator(priv_k):
    #𝑃𝐾 = 𝑝 − 𝑆𝑘
    pub_k = p - priv_k
    print(f'Public Key: {pub_k:#x}')
    return pub_k

def reset_files():
    current_folder = os.getcwd()
    path_to_tv = current_folder + '/../modelsim/tv'
    for filename in os.listdir(path_to_tv):
        if filename != 'dictionary.txt':
            with open('../modelsim/tv/' + filename, 'w') as file:
                file.write('')

def main():
    reset_files()

    secretsGenerator = secrets.SystemRandom()

    W_sK = bytes(f'{secretsGenerator.randrange(1, 222):08b}', 'ascii')
    with open('../modelsim/tv/Walter_SK.txt', 'wb') as file:
        file.write(W_sK)

    J_sK = bytes(f'{secretsGenerator.randrange(1, 222):08b}', 'ascii')
    with open('../modelsim/tv/Jesse_SK.txt', 'wb') as file:
        file.write(J_sK)

    with open('../modelsim/tv/dictionary.txt', 'r') as file:
        all_the_lines = file.readlines()
        line_to_read = secretsGenerator.randrange(1, len(all_the_lines))
        plaintext_w = all_the_lines[line_to_read - 1]
        line_to_read2 = secretsGenerator.randrange(1, len(all_the_lines))
        plaintext_j = all_the_lines[line_to_read2 - 1]

    with open('../modelsim/tv/Walter_PT.txt', 'w') as file:
        file.write(plaintext_w)
    
    with open('../modelsim/tv/Jesse_PT.txt', 'w') as file:
        file.write(plaintext_j)

    W_sK = int(W_sK, 2)
    print(f'Walter Key: {int(str(W_sK).encode("utf-8").hex(), 16):#x}')
    J_sK = int(J_sK, 2)
    print(f'Jesse Key: {int(str(J_sK).encode("utf-8").hex(), 16):#x}')
    
    W_pK = key_generator(W_sK)
    J_pK = key_generator(J_sK)
    
    print(f'Walter PT: {int(plaintext_w.encode("utf-8").hex(), 16):#x}')
    ct_w = encrypt(plaintext_w, J_pK)
    print(f'Walter CT: {int(ct_w.encode("utf-8").hex(), 16):#x}')
    deciphertext_w = decrypt(ct_w, J_sK)
    print(f'Jesse should decipher text: {int(deciphertext_w.encode("utf-8").hex(), 16):#x}')
    
    print(f'Jesse PT: {int(plaintext_j.encode("utf-8").hex(), 16):#x}')
    ct_j = encrypt(plaintext_j, W_pK)
    print(f'Jesse CT: {int(ct_j.encode("utf-8").hex(), 16):#x}')
    deciphertext_j = decrypt(ct_j, W_sK)
    print(f'Walter should decipher text: {int(deciphertext_j.encode("utf-8").hex(), 16):#x}')

    #deciphertext_j = decrypt(ct_j, J_sK)
    

if __name__ == '__main__':
    main()

