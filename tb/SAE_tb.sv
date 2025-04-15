module SAE_tb_checks;

    reg clk = 1'b0;
    // Clock is toggled every 5 time units
    always #5 clk = !clk;
  
    reg reset_n = 1'b0;
    // Reset is set to 0 for the first 12.8 time units
    initial #12.8 reset_n = 1'b1;

    /*
    We define two instances to test the functionality of the SAE module, as indicated in the specification. 
    We refer to the figure in the specification and create one instance of the module for Walter and one for Jesse.
    */

    // WALTER
    // mode_w: mode input for the SAE module for Walt
    reg [1:0] mode_w;
    // input_data_w: input_data input for the SAE module for Walt
    reg [7:0] input_data_w;
    // input_key_w: input_key input for the SAE module for Walt
    reg [7:0] input_key_w;
    // valid_inputs_w: valid_input input for the SAE module for Walt
    reg valid_inputs_w;
    // output_ready_w: output_ready output for the SAE module for Walt
    wire output_ready_w;
    // output_data_w: output_data output for the SAE module for Walt
    wire [7:0] output_data_w;
    // err_invalid_seckey_w: err_invalid_seckey output for the SAE module for Walt
    wire err_invalid_seckey_w;

    SAE SAE_walt(
     .clk                       (clk)
    ,.reset_n                   (reset_n)
    ,.mode                      (mode_w)
    ,.input_data                (input_data_w)
    ,.input_key                 (input_key_w)
    ,.valid_input               (valid_inputs_w)
    ,.output_data               (output_data_w)
    ,.output_ready              (output_ready_w)
    ,.err_invalid_seckey        (err_invalid_seckey_w)
    );

    // JESSE
    // mode_j: input mode for the SAE module for Jesse
    reg [1:0] mode_j;
    // input_data_j: input_data input for the SAE module for Jesse
    reg [7:0] input_data_j;
    // input_key_j: input_key input for the SAE module for Jesse
    reg [7:0] input_key_j;
    // valid_inputs_j: valid_input input for the SAE module for Jesse
    reg valid_inputs_j;
    // output_ready_j: output_ready output for the SAE module for Jesse
    wire output_ready_j;
    // output_data_j: output_data output for the SAE module for Jesse
    wire [7:0] output_data_j;
    // err_invalid_seckey_j: err_invalid_seckey output for the SAE module for Jesse
    wire err_invalid_seckey_j;

    SAE sae_jesse(
     .clk                       (clk)
    ,.reset_n                   (reset_n)
    ,.mode                      (mode_j)
    ,.input_data                (input_data_j)
    ,.input_key                 (input_key_j)
    ,.valid_input               (valid_inputs_j)
    ,.output_data               (output_data_j)
    ,.output_ready              (output_ready_j)
    ,.err_invalid_seckey        (err_invalid_seckey_j)
    );
    
    int FILE;             // Return value of open()
    reg [7:0] PT_W [$];   // Walter's pt
    reg [7:0] CT_W [$];   // Walter's ct
    reg [7:0] PT_J [$];   // Jesse's pt
    reg [7:0] CT_J [$];   // Jesse's ct

    // Support variables used as the argument of scanf()
    string char_w;
    string char_w2;
    string char_j;
    string char_j2;

    /*
    The testbench will use write and read operations from files to simulate data exchange between the two modules. Specifically:
    - Walt's public key will be saved in the file Walter_PK.txt, to simulate sending the key to Jesse.
    - Jesse's public key will be saved in the file Jesse_PK.txt, to simulate sending the key to Walt.
    - The ct produced by Walter encrypting his own pt will be saved in the file Jesse_CT.txt, to simulate sending the ct to Jesse.
    */
	initial begin
        @(posedge reset_n);


        /* *
        * WALTER PUBLIC KEY GENERATION
        * */
        
        @(posedge clk);
        // Walter opens the file containing his private key, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Walter_SK.txt", "rb");
        if (FILE) begin
            $display("File Walter_SK was opened successfully : %0d", FILE);
        end
        else begin 
            $display("File Walter_SK was NOT opened successfully : %0d", FILE);
            $finish;
        end
        // Walter reads his own private key from the file, if the read fails the execution is aborted.
        if($fscanf(FILE, "%b", input_key_w) == 1)begin
            $display("Walt's private key was successfully loaded");
        end
        else begin
            $display("Walt's private key was NOT loaded correctly");
            $finish;
        end
        // Walter closes the previously opened file
        $fclose(FILE);

        // Inputs are set for the public key generation operation to be carried out.
        mode_w = 2'b01;         // 01: Generate public key
        input_data_w = 8'd0;    // 0: No data input
        valid_inputs_w = 1'b1;  // 1: Data input is valid

        // Inputs_valid is set to 0 to signal that it is possible to operate on data sampled from registers and not sample subsequent input values.
        @(posedge clk);         // Wait for the next clock edge
        valid_inputs_w = 1'b0;  // 0: Data input is not valid

        // Execution continues waiting for output_ready_w to go to 1, checking that the non-compliant private key error does not go to 1.
        @(posedge clk);         // Wait for the next clock edge
        #3 while (output_ready_w != 1'b1) begin
            if(err_invalid_seckey_w == 1'b1) begin
                $display("Walt's secret key has an invalid value");
                $finish;
            end
            $display("Walt's public key is NOT yet ready");
        end
        $display("Walt's public key was generated");

        // Walter opens the file that will contain his public key, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Walter_PK.txt", "wb");
        if (FILE) begin
            $display("File Walter_PK was opened successfully : %0d", FILE);
        end
        else begin 
            $display("File Walter_PK was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // Walter writes his own public key inside the file, then closes it.
        $fdisplay(FILE, "%b", output_data_w);
        $fclose(FILE);

        // mode_w is set to 00 (no action) to prevent module operations from continuing.
        mode_w = 2'b00; // 00: No action
        @(posedge clk); // Wait for the next clock edge


        /* *
        * JESSE PUBLIC KEY GENERATION
        * */

        // Jesse opens the file containing his private key, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Jesse_SK.txt", "rb");
        if (FILE) begin
            $display("File Jesse_SK was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Jesse_SK was NOT opened successfully : %0d", FILE);
            $finish;
        end  
        // Jesse reads his own private key from the file, if the read fails the execution is aborted.
        if($fscanf(FILE, "%b", input_key_j) == 1) begin
            $display("Jesse's private key was successfully loaded");
        end
        else begin
            $display("Jesse's private key was NOT loaded correctly during pub key generation");
            $finish;
        end
        // Jesse closes the previously opened file
        $fclose(FILE);

        // Inputs are set for the public key generation operation to be carried out.
        mode_j = 2'b01;         // 01: Generate public key
        input_data_j = 8'd0;    // 0: No data input
        valid_inputs_j = 1'b1;  // 1: Data input is valid

        // Inputs_valid is set to 0 to signal that it is possible to operate on data sampled from registers and not sample subsequent input values.
        @(posedge clk);         // Wait for the next clock edge 
        valid_inputs_j = 1'b0;  // 0: Data input is not valid

        // Execution continues waiting for output_ready_j to go to 1, checking that the non-compliant private key error does not go to 1.
        @(posedge clk);         // Wait for the next clock edge
        #3 while (output_ready_j != 1'b1) begin 
            if(err_invalid_seckey_j == 1'b1) begin
                $display("Jesse's secret key has an invalid value");
                $finish;
            end
            $display("Jesse's public key is NOT yet ready");
        end
        $display("Jesse's public key was generated");

        // Jesse opens the file that will contain his public key, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Jesse_PK.txt", "wb");
        if (FILE) begin
            $display("File Jesse_PK was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Jesse_PK was NOT opened successfully : %0d", FILE);
            $finish;
        end 

        // Jesse writes his own public key inside the file, then closes it.
        $fdisplay(FILE, "%b", output_data_j);
        $fclose(FILE);

        // mode_j is set to 00 (no action) to prevent module operations from continuing.
        mode_j = 2'b00; // 00: No action
        @(posedge clk); // Wait for the next clock edge


//************************************************************************************************** PROTOCOL *****************************************************************************************************************

        /* *
        * WALTER ENCRYPTS PT
        * */

        // Walter opens the file containing Jesse's public key, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Jesse_PK.txt", "rb");
        if (FILE)  begin
            $display("File Jesse_PK was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Jesse_PK was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // Walter reads Jesse's public key from the file, if the read fails the execution is aborted.
        if($fscanf(FILE, "%b", input_key_w) == 1) begin
            $display("Jesse's public key was successfully loaded");
        end
        else begin
            $display("Jesse's public key was NOT loaded correctly");
            $finish;
        end
        $fclose(FILE);

        // Walter opens the file containing his own pt, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Walter_PT.txt", "r");
        if (FILE)  begin
            $display("File Walter_PT was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Walter_PT was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // For each pt character, the inputs for the encryption operation are set.
        while($fscanf(FILE, "%c", char_w) == 1) begin
            input_data_w = int'(char_w);    // The character is converted to an integer
            mode_w = 2'b10;                 // 10: Encrypt
            valid_inputs_w = 1'b1;          // 1: Data input is valid
            @(posedge clk);
            // inputs_valid is set to 0 so as to signal that it is possible to operate on data sampled from the registers and not sample subsequent input values.
            valid_inputs_w = 1'b0;          // 0: Data input is not valid
            @(posedge clk);                 // Wait for the next clock edge
            // Execution continues waiting for output_ready_w to go to 1, checking that the nonconforming pt character error does not change to 1.           
            #3 while(output_ready_w != 1'b1) begin
                //do nothing, just wait
            end
            // Character ct has been computed and is inserted into the queue.
            CT_W.push_back(output_data_w);
        end
        $fclose(FILE);

        // Walter opens the file that will contain the ct sent to Jesse, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Jesse_CT.txt", "w");
        if (FILE) begin
            $display("File Jesse_CT was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Jesse_CT was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // Walter writes the ct inside the file, then closes it.
        foreach(CT_W[i]) begin
            $fwrite(FILE, "%c", CT_W[i]);
        end
        $fclose(FILE);

        // mode_w is set to 00 (no action) to prevent module operations from continuing. 
        mode_w = 2'b00; // 00: No action
        @(posedge clk); // Wait for the next clock edge


        /* *
        * JESSE DECRYPTS CT
        * */

        // Jesse opens the file containing his own private key, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Jesse_SK.txt", "rb");
        if (FILE) begin
            $display("File Jesse_SK was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Jesse_SK was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // Jesse reads his own private key from the file, if the read fails the execution is aborted.
        if($fscanf(FILE, "%b", input_key_j) == 1) begin
            $display("Jesse's private key was successfully loaded");
        end
        else begin
            $display("Jesse's private key was NOT loaded correctly during decryption");
            $finish;
        end
        // Jesse closes the previously opened file
        $fclose(FILE);

        // Jesse opens the file containing the ct, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Jesse_CT.txt", "r");
        if (FILE) begin
            $display("File Jesse_CT was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Jesse_CT was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // For each ct character, the inputs for the decryption operation are set.
        while($fscanf(FILE, "%c", char_j) == 1) begin
            input_data_j = int'(char_j);    // The character is converted to an integer
            mode_j = 2'b11;                 // 11: Decrypt
            valid_inputs_j = 1'b1;          // 1: Data input is valid
            @(posedge clk);                 // Wait for the next clock edge
            // inputs_valid is set to 0 so as to signal that it is possible to operate on data sampled from the registers and not sample subsequent input values.
            valid_inputs_j = 1'b0;          // 0: Data input is not valid
            @(posedge clk);                 // Wait for the next clock edge
            // Execution continues waiting for output_ready_j to go to 1, checking that the nonconforming ct character error does not go to 1.
            #3 while(output_ready_j != 1'b1) begin
                // Do nothing, just wait
            end
            // Character pt has been computed and is inserted into the queue.
            PT_J.push_back(output_data_j);
        end
        $fclose(FILE);

        // mode_j is set to 00 (no action) to prevent module operations from continuing.
        mode_j = 2'b00; // 00: No action
        @(posedge clk); // Wait for the next clock edge


        /* *
        * CHECK THAT ORIGINAL PT = DECRYPTED PT
        * */

        // File containing the initial pt is opened, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Walter_PT.txt", "r");
        if (FILE) begin
            $display("File Walter_PT was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Walter_PT was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // Initial pt is saved within the PT_W queue.
        while($fscanf(FILE, "%c", char_w2) == 1) begin
            PT_W.push_back(int'(char_w2));
        end
        $fclose(FILE);

        // The two plaintexts are compared to verify that they are the same.
        if(PT_J == PT_W) begin
            $display("Plaintexts MATCH!");
        end
        else begin
            $display("Plaintexts NOT match");
        end

        // Delete the content of PT_J and PT_W
        PT_J.delete();
        PT_W.delete();
        // Delete the content of CT_W
        CT_W.delete();


        /* *
        * JESSE ENCRYPTS PT
        * */

        // Jesse opens the file containing Walter's public key, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Walter_PK.txt", "rb");
        if (FILE)  begin
            $display("File Walter_PK was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Walter_PK was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // Jesse reads Walter's public key from the file, if the read fails the execution is aborted.
        if($fscanf(FILE, "%b", input_key_j) == 1) begin
            $display("Walter's public key was successfully loaded");
        end
        else begin
            $display("Walter's public key was NOT loaded correctly");
            $finish;
        end
        $fclose(FILE);

        // Jesse opens the file containing his own pt, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Jesse_PT.txt", "r");
        if (FILE)  begin
            $display("File Jesse_PT was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Jesse_PT was NOT opened successfully : %0d", FILE);
            $finish;
        end
        // For each pt character, the inputs for the encryption operation are set.
        while($fscanf(FILE, "%c", char_j) == 1) begin
            input_data_j = int'(char_j);    // The character is converted to an integer
            mode_j = 2'b10;                 // 10: Encrypt
            valid_inputs_j = 1'b1;          // 1: Data input is valid
            @(posedge clk);
            // inputs_valid is set to 0 so as to signal that it is possible to operate on data sampled from the registers and not sample subsequent input values.
            valid_inputs_j = 1'b0;          // 0: Data input is not valid
            @(posedge clk);                 // Wait for the next clock edge
            // Execution continues waiting for output_ready_w to go to 1, checking that the nonconforming pt character error does not change to 1.         
            #3 while(output_ready_j != 1'b1) begin
                // Do nothing, just wait
            end
            // Character ct has been computed and is inserted into the queue.
            CT_J.push_back(output_data_j);
        end
        $fclose(FILE);

        // Jesse opens the file that will contain the ct sent to Walter, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Walter_CT.txt", "w");
        if (FILE) begin
            $display("File Walter_CT was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Walter_CT was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // Jesse writes the ct inside the file, then closes it.
        foreach(CT_J[i]) begin
            $fwrite(FILE, "%c", CT_J[i]);
        end
        $fclose(FILE);

        // mode_w is set to 00 (no action) to prevent module operations from continuing. 
        mode_j = 2'b00; // 00: No action
        @(posedge clk); // Wait for the next clock edge


        /* *
        * WALTER DECRYPTS PT
        * */

        // Walter opens the file containing his own private key, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Walter_SK.txt", "rb");
        if (FILE) begin
            $display("File Walter_SK was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Walter_SK was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // Walter reads his own private key from the file, if the read fails the execution is aborted.
        if($fscanf(FILE, "%b", input_key_w) == 1) begin
            $display("Walter's private key was successfully loaded");
        end
        else begin
            $display("Walter's private key was NOT loaded correctly during decryption");
            $finish;
        end
        // Walter closes the previously opened file
        $fclose(FILE);

        // Walter opens the file containing the ct, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Walter_CT.txt", "r");
        if (FILE) begin
            $display("File Walter_CT was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Walter_CT was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // For each ct character, the inputs for the decryption operation are set.
        while($fscanf(FILE, "%c", char_w) == 1) begin
            input_data_w = int'(char_w);    // The character is converted to an integer
            mode_w = 2'b11;                 // 11: Decrypt
            valid_inputs_w = 1'b1;          // 1: Data input is valid
            @(posedge clk);                 // Wait for the next clock edge
            // inputs_valid is set to 0 to signal that it is possible to operate on data sampled from registers and not sample subsequent input values.
            valid_inputs_w = 1'b0;          // 0: Data input is not valid
            @(posedge clk);                 // Wait for the next clock edge
            // Execution continues waiting for output_ready_j to go to 1, checking that the nonconforming ct character error does not go to 1.
            #3 while(output_ready_w != 1'b1) begin
                // Do nothing, just wait
            end
            // Character pt has been computed and is inserted into the queue.
            PT_W.push_back(output_data_w);
        end
        $fclose(FILE);

        // mode_w is set to 00 (no action) to prevent module operations from continuing.
        mode_w = 2'b00; // 00: No action
        @(posedge clk); // Wait for the next clock edge

        /* * 
        * CHECK THAT ORIGINAL PT = DECRYPTED PT
        * */

        // File containing the initial pt is opened, if the opening fails the execution is aborted.
        FILE = $fopen("tv/Jesse_PT.txt", "r");
        if (FILE) begin
            $display("File Jesse_PT was opened successfully : %0d", FILE);
        end
        else begin
            $display("File Jesse_PT was NOT opened successfully : %0d", FILE);
            $finish;
        end

        // Initial pt is saved within the PT_J queue.
        while($fscanf(FILE, "%c", char_w2) == 1) begin
            PT_J.push_back(int'(char_w2));
        end
        $fclose(FILE);

        // The two plaintexts are compared to verify that they are the same.
        if(PT_J == PT_W) begin
            $display("Plaintexts MATCH!");
        end
        else begin
            $display("Plaintexts NOT match");
        end


    $stop;

    end
endmodule