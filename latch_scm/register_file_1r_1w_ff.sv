// Copyright 2014-2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Company:        Institute of Integrated Systems // ETH Zurich              //
//                                                                            //
// Engineer:      Igor Loi - igor.loi@unibo.it                                //
//                                                                            //
// Additional contributions by:                                               //
//                 Francesco Conti                                            //
//                 Davide Rossi                                               //
//                 Michael Gautschi                                           //
//                 Antonio Pullini                                            //
//                                                                            //
// Create Date:    12/03/2015                                                 //
// Design Name:    scm memory                                                 //
// Module Name:    register_file_1r_1w                                        //
// Project Name:   HWCE                                                       //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    scm memory multiport: FOR HWCE                             //
//                                                                            //
// Revision:                                                                  //
// Revision v0.1 - File Created                                               //
// Revision v0.2 - Improved Identation                                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

module register_file_1r_1w_ff
#(
    parameter ADDR_WIDTH    = 5,
    parameter DATA_WIDTH    = 32
)
(
    input  logic                                  clk,
    input  logic                                  rst_n,

    // Read port
    input  logic                                  ReadEnable,
    input  logic [ADDR_WIDTH-1:0]                 ReadAddr,
    output logic [DATA_WIDTH-1:0]                 ReadData,


    // Write port
    input  logic                                  WriteEnable,
    input  logic [ADDR_WIDTH-1:0]                 WriteAddr,
    input  logic [DATA_WIDTH-1:0]                 WriteData
);

    localparam    NUM_WORDS = 2**ADDR_WIDTH;

    // Read address register, located at the input of the address decoder
    logic [ADDR_WIDTH-1:0]                        RAddrRegxDP; 
    logic [NUM_WORDS-1:0]                         RAddrOneHotxD;


    logic [DATA_WIDTH-1:0]                        MemContentxDP[NUM_WORDS];

    logic [NUM_WORDS-1:0]                         WAddrEn;

    int unsigned i;

    //-----------------------------------------------------------------------------
    //-- READ : Read address register
    //-----------------------------------------------------------------------------
    always_ff @(posedge clk)
    begin : p_RAddrReg
        if(ReadEnable)
            RAddrRegxDP <= ReadAddr;
    end


    //-----------------------------------------------------------------------------
    //-- READ : Read address decoder RAD
    //-----------------------------------------------------------------------------  
    always_comb
    begin : p_RAD
        RAddrOneHotxD = '0;
        RAddrOneHotxD[RAddrRegxDP] = 1'b1;
    end
    assign ReadData = MemContentxDP[RAddrRegxDP];


    //-----------------------------------------------------------------------------
    //-- WRITE : Write Address Decoder (WAD), combinatorial process
    //-----------------------------------------------------------------------------
    always_comb
    begin : p_WAD
        for(i=0; i<NUM_WORDS; i++)
        begin : p_WordIter
            WAddrEn[i] = ((WriteEnable == 1'b1 ) && (WriteAddr == i)) ? 1'b1 : 1'b0;
        end
    end

    //-----------------------------------------------------------------------------
    //-- WRITE : Write operation
    //-----------------------------------------------------------------------------  
    //-- Generate M = WORDS sequential processes, each of which describes one
    //-- word of the memory. The processes are synchronized with the clocks
    //-- ClocksxC(i), i = 0, 1, ..., M-1
    //-- Use active low, i.e. transparent on low latches as storage elements
    //-- Data is sampled on rising clock edge

    generate
       for(genvar k=0; k<NUM_WORDS; k++)
         begin: gen_rf
            
           always_ff @(posedge clk or negedge rst_n)
           begin: reg_wdata
              if (rst_n == 1'b0) begin
                 MemContentxDP[k] = '0;
              end else begin
                 if (WAddrEn[k] == 1'b1) begin
                    MemContentxDP[k] = WriteData;
                 end
              end
           end
         end // block: gen_rf
    endgenerate   

endmodule
