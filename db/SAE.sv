`define NULLCHAR 8'h00

localparam p = 8'd223;

/* *
* KEY GENERATION
* */

// Submodule that performs the operation of key-pair generation (mode = 2'b01)
module pubkey_gen_mod(
     input  selection               // Control variable that activates the circuit
    ,input  [7:0] secrKey           // Secret key used as input to calculate the public key
    ,output reg [7:0] pubKey        // Public key calculated as Pk = p - Sk
    ,output reg pkg_ready           // Output bit that indicates when the output (public key) is ready
);

reg [7:0] result; // 0 to 226

always @ (*) begin
    // Selection worth 1 if mode is 2'b01
    if(selection == 1'b1) begin
        result = p - secrKey;
        pkg_ready = 1'b1; 
        pubKey = result[7:0];
    end
    // Circuit was not selected, mode != 2'b01
    else begin
        result = 8'h0;
        pubKey = `NULLCHAR;
        pkg_ready = 1'b0;
    end
end

endmodule


/* *
* ENCRYPTION
* */

// Submodule that performs the operation of encryption (mode = 2'b10)
module encryption_mod(
     input  selection               // Control variable that activates the circuit
    ,input  [7:0] pt                // pt input we want to encrypt
    ,input  [7:0] pubKey            // Public key that we will use to encrypt the pt
    ,output reg [7:0] ct            // Output ct calculated as C[i] = (P[i] + Pk) mod p
    ,output reg enc_ready           // Output bit indicating when the output (the ct) is ready
);

reg signed [8:0] sum;
reg[8:0] result;

always @ (*) begin
    // Selection worth 1 if mode is 2'b10
    if(selection) begin
        sum = pt + pubKey;
        // 0 < sum < 223: result = sum, no modulo calculation is needed
        if (sum >= 9'd0 && sum < 9'd223) begin
            result = sum;
            ct = result[7:0];
            enc_ready = 1'b1;
        end
        // 223 < sum < 256: result = sum - 223 = modulo calculation
        else begin
            // Modulo calculation optimized with subtraction
            result = sum - p;
            ct = result[7:0];
            enc_ready = 1'b1;
        end       
    end
    // Case when the circuit was not selected, mode != 2'b10
    else begin
        sum = 9'h0;
        result = 9'h0;
        ct = `NULLCHAR;
        enc_ready = 1'b0;
    end
end

endmodule


/* *
* DECRYPTION
* */

// Submodule that performs the operation of decryption (mode = 2'b11)
module decryption_mod (
     input selection            // Control variable that activates the circuit
    ,input [7:0] ct             // ct input we want to decrypt
    ,input [7:0] secrKey        // Public key used to decrypt ct
    ,output reg [7:0] pt        // Output pt calculated as P[i] = (C[i] + Sk) mod p
    ,output reg dec_ready       // Output bit indicating when the output (the pt) is ready
);

reg[9:0] sum;
reg[9:0] result;

always @ (*) begin
    // Selection worth 1 if mode is 2'b11
    if(selection) begin
        sum = ct + secrKey;
        // 446 (223 * 2) < sum < 510 (max value of register C[i] + Sk = 255 + 255 = 510): result = sum - 446 = modulo calculation
        if(sum >= 10'h1BE && sum <= 10'd510) begin
            result = sum - 10'h1BE;
        end
        // 223 < sum < 446: result = sum - 223 = modulo calculation
        else if (sum >= 10'h0DF && sum <= 10'h1BE) begin
            result = sum - 10'h0DF;
        end
        // sum < 223: result = sum, no modulo calculation is needed
        else begin
            result = sum;
        end
        pt = result[7:0];
        dec_ready = 1'b1;
    end
    // Case when the circuit was not selected, mode != 2'b11
    else begin
        result = 10'h0;
        sum = 10'h0;
        pt = `NULLCHAR;
        dec_ready = 1'b0;
    end
end

endmodule


/* *
* SAE TOP LEVEL MODULE
* */

module SAE (
     input clk
    ,input reset_n                  // Reset signal: resets the module to its initial state when it is 0 (active low)
    ,input [1:0] mode               // Mode selected by the user (2'b01: key-pair generation, 2'b10: encryption, 2'b11: decryption)
    ,input [7:0] input_data         // Input data provided by the user, may be a pt or a ct depending on the mode
    ,input [7:0] input_key          // Input key provided by the user, may be a secret key or a public key depending on the mode
    ,output reg [7:0] output_data   // Output of the module: can be a public key, a pt or a ct depending on the mode
    ,input valid_input              // User-supplied bit that indicates when inputs are valid and can be sampled by the module
    ,output reg output_ready        // Output bit indicating when the output is ready
    ,output err_invalid_seckey      // Output bit indicating that the secret key is invalid
);

// Sample the value of mode, allows to avoid errors due to timing conditions of output_ready
reg [1:0] mode_sampled;
// Sample the value of valid_input, allows to avoid errors due to timing and input variations
reg in_valid;
// Value of input_data
reg [7:0] data;
// Value of input_key
reg [7:0] key;
// Input to key-pair generation and decryption submodules
reg [7:0] secrKey;
// Input to encryption submodule
reg [7:0] pubKey;
// Selection for the key-pair generation submodule
reg pkg_sel;
// Output of the key-pair generation submodule is ready
wire pkg_ready;
// Output of the key-pair generation submodule
wire [7:0] pkg_output;
// Selection for the encryption submodule
reg enc_sel;
// Output of the encryption submodule is ready
wire enc_ready;
// Output wire indicating the output of the encryption submodule
wire [7:0] enc_output;
// Selection for the decryption submodule
reg dec_sel;
// Output of the decryption submodule is ready
wire dec_ready;
// Output of the decryption submodule
wire [7:0] dec_output;

reg [7:0] ct;
reg [7:0] pt;

pubkey_gen_mod pubkey_gen (
    .selection           (pkg_sel)
    ,.secrKey            (secrKey)
    ,.pubKey             (pkg_output)
    ,.pkg_ready          (pkg_ready)
);

encryption_mod encryption(
    .selection           (enc_sel)
    ,.pt                 (pt)
    ,.pubKey             (pubKey)
    ,.ct                 (enc_output)
    ,.enc_ready          (enc_ready)
);

decryption_mod decryption(
    .selection           (dec_sel)
    ,.ct                 (ct)
    ,.secrKey            (secrKey)
    ,.pt                 (dec_output)
    ,.dec_ready          (dec_ready)
);


/* 
err_invalid_seckey is worth 1 when the mode is 2'b01 or 2'b11 and the key is 0 or greater than 222
Checking in_valid avoids having errors in the input transition phase, which would block the entire circuit
*/
assign err_invalid_seckey = (mode[0] == 1'b1) && (key < 1 || key > p - 1) && in_valid == 1'b1;

// Sample values and assign to the correct variables (which will be the input for the submodules) depending on the mode received
always @(*) begin
    // If there are no errors in the input data and if in_valid is 1
    if(!err_invalid_seckey && !valid_input) begin
        case(mode)
        // Key pair generation
        2'b01: begin
            ct = `NULLCHAR;
            pt = `NULLCHAR;
            secrKey = key;
            pubKey  = `NULLCHAR;
            pkg_sel = 1'b1;     // Key pair generation submodule is selected
            enc_sel = 1'b0; 
            dec_sel = 1'b0;
            end
        // Encryption
        2'b10: begin 
            ct = `NULLCHAR;
            pt = data;
            secrKey = `NULLCHAR;
            pubKey  = key;
            pkg_sel = 1'b0; 
            enc_sel = 1'b1;     // Encryption submodule is selected
            dec_sel = 1'b0;     
            end
        // Decryption
        2'b11: begin 
            ct = data; 
            pt = `NULLCHAR;
            secrKey = key; 
            pubKey  = `NULLCHAR;
            pkg_sel = 1'b0; 
            enc_sel = 1'b0; 
            dec_sel = 1'b1;     // Decryption submodule is selected
            end
        // 2'b00: no action
        default: begin 
            ct = `NULLCHAR;
            pt  = `NULLCHAR;
            secrKey = `NULLCHAR;
            pubKey  = `NULLCHAR;
            pkg_sel = 1'b0; 
            enc_sel = 1'b0; 
            dec_sel = 1'b0;
            end
        endcase
    end
    // If inputs are invalid
    else begin
        ct = `NULLCHAR;
        pt = `NULLCHAR;
        secrKey = `NULLCHAR;
        pubKey  = `NULLCHAR;
        pkg_sel = 1'b0; 
        enc_sel = 1'b0; 
        dec_sel = 1'b0;
    end
end

// Input and output values are sampled at each clock 
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
        mode_sampled <= 2'b00;
		data <= `NULLCHAR;
		key <= `NULLCHAR;
        in_valid <= 1'b0;
        output_ready <= 1'b0;               // FIXED: output_ready is set to 0 when reset_n is 0
	end
    else begin
        // If there are no errors, the value of in_valid is sampled from that of valid_input
        if(!err_invalid_seckey) begin
            in_valid <= valid_input;        // valid_input is sampled at each clock cycle and in_valid is updated
        end
        /* 
        In the presence of errors, the value of in_valid remains stable so that it does not go to 0. 
        If it went to 0, the err_invalid_seckey error would not be reported, leading to the execution of calculations with invalid values.
        */
        else begin
            in_valid <= in_valid;           // in_valid remains stable
        end
		if(valid_input) begin       
            // Values are sampled
			data <= input_data;
			key <= input_key;
            mode_sampled <= mode;           // mode_sampled is updated with the value of mode
		end
		else begin 
            // Values remain stable
			data <= data; 
			key <= key;
            mode_sampled <= mode_sampled;
		end
        case(mode)
        // Key-pair generation
        2'b01: begin
            if(mode_sampled == mode) begin
                output_ready <= pkg_ready;  // Output is ready when the key-pair generation is ready        
            end
            else begin
                output_ready <= 1'b0;
            end
            output_data <= pkg_output;      // Output = public key
        end
        // Encryption
        2'b10: begin
            if(mode_sampled == mode) begin
                output_ready <= enc_ready;  // Output is ready when the encryption is ready    
            end
            else begin
                output_ready <= 1'b0;
            end
            output_data <= enc_output;      // Output = ct
        end
        // Decryption
        2'b11: begin
            if(mode_sampled == mode) begin
                output_ready <= dec_ready;  // Output is ready when the decryption is ready    
            end
            else begin
                output_ready <= 1'b0;
            end
            output_data <= dec_output;      // Output = pt
        end
        // 2'b00: no action
        default: begin
            output_ready <= 1'b0;
            output_data <= `NULLCHAR;
        end
        endcase
        end
end
endmodule