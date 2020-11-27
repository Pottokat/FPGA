`include "wb.sv"
`include "arbiter.v"
`include "priority_encoder.v"

module Slave #( 
	parameter DATA_WIDTH = 32,              // width of data bus in bits (8, 16, 32, or 64)
	parameter ADDR_WIDTH = 32,              // width of address bus in bits
	parameter SELECT_WIDTH = (DATA_WIDTH/8) // width of word select bus (1, 2, 4, or 8)
	) (
		input logic clk,
		input logic rst,
		input logic [ADDR_WIDTH-1:0] adr_i,	// ADR_I() address input
		input logic	[DATA_WIDTH-1:0] dat_i,	// DAT_I() data in
		output logic [DATA_WIDTH-1:0] dat_o,	// DAT_O() data out
		input logic	we_i,  	// WE_I write enable input
		input logic	[SELECT_WIDTH-1:0] sel_i,	// SEL_I() select input
		input logic	stb_i,	// STB_I strobe input
		output logic ack_o,	// ACK_O acknowledge output
		output logic err_o,	// ERR_O error output
		output logic rty_o,	// RTY_O retry output
		input logic	cyc_i  	// CYC_I cycle input
	);
	
   enum {IDLE, WAIT} state, next;

   /* FSM */
   always_ff @(posedge clk)
     if (rst)
       state <= IDLE;
     else
       state <= next;

   always_comb
     begin
        next = state;

        case (state)
          IDLE: if (stb_i) next = WAIT;
      //    WAIT: if (ack_i) next = IDLE;
        endcase
     end
endmodule

module Master #( 
	parameter DATA_WIDTH = 32,              // width of data bus in bits (8, 16, 32, or 64)
	parameter ADDR_WIDTH = 32,              // width of address bus in bits
	parameter SELECT_WIDTH = (DATA_WIDTH/8) // width of word select bus (1, 2, 4, or 8)
	) (
		input logic clk,
		input logic rst,
		output logic [ADDR_WIDTH-1:0] adr_o,	// ADR_O() address output
		input logic	[DATA_WIDTH-1:0] dat_i,	// DAT_I() data in
		output logic [DATA_WIDTH-1:0] dat_o,	// DAT_O() data out
		output logic we_o, 	// WE_O write enable output
		output logic [SELECT_WIDTH-1:0] sel_o,	// SEL_O() select output
		output logic stb_o,	// STB_O strobe output
		input logic	ack_i,	// ACK_I acknowledge input
		input logic	err_i,	// ERR_I error input
		input logic	rty_i,	// RTY_I retry input
		output logic cyc_o 	// CYC_O cycle output
	);

endmodule

//module MuxN #( 
//	parameter int unsigned INPUTS = 4,
//	parameter int unsigned WIDTH = 8
//)(
//	output logic [WIDTH-1:0] out,
//	input logic sel[INPUTS],
//	input logic [WIDTH-1:0]  in [INPUTS]
//);
//
//	always_comb
//	begin
//	  out = {WIDTH{1'b0}};
//	  for (int unsigned index = 0; index < INPUTS; index++)
//	  begin
//			out |= {WIDTH{sel[index]}} & in[index];
//	  end
//	end
//endmodule

module Mux #( 
	parameter INPUTS = 4, // num inputs
	parameter WIDTH = 8 // input width
)(
	input [INPUTS-1:0] sel,
	input [WIDTH-1:0] in [INPUTS],
	output [WIDTH-1:0] out
	);

	always_comb 
		out = in[sel];
endmodule

module Mux1 #( 
	parameter INPUTS = 4, // num inputs
	parameter WIDTH = 8 // input width
)(
	input [INPUTS-1:0] sel,
	input [WIDTH-1:0] in,
	output out
	);

	always_comb 
		out = in[sel];
endmodule

module Adress_comparator #(
	parameter SLAVES = 2,
	parameter MASTERS = 2,
	parameter DATA_WIDTH = 32,              // width of data bus in bits (8, 16, 32, or 64)
	parameter ADDR_WIDTH = 32,              // width of address bus in bits
	parameter SELECT_WIDTH = (DATA_WIDTH/8) // width of word select bus (1, 2, 4, or 8)
)(
	input logic [ADDR_WIDTH-1:0] adr,
	output logic [SLAVES-1:0] acmp
	);
	
//	logic [SLAVES-1:0] tmp;
//	always_comb begin
//		tmp[0:0] = adr[ADDR_WIDTH-1:ADDR_WIDTH-1] & adr[ADDR_WIDTH-2:ADDR_WIDTH-2];
//		tmp[1:1] = adr[ADDR_WIDTH-1:ADDR_WIDTH-1] & ( ~ adr[ADDR_WIDTH-2:ADDR_WIDTH-2]);
//		tmp[2:2] = (~ adr[ADDR_WIDTH-1:ADDR_WIDTH-1]) & adr[ADDR_WIDTH-2:ADDR_WIDTH-2];
//		tmp[3:3] = (~ adr[ADDR_WIDTH-1:ADDR_WIDTH-1]) & ( ~ adr[ADDR_WIDTH-2:ADDR_WIDTH-2]);
//	end
//	
//	assign acmp = tmp;
	
endmodule

module Intercom #(
	parameter SLAVES = 2,
	parameter MASTERS = 2,
	parameter DATA_WIDTH = 32,              // width of data bus in bits (8, 16, 32, or 64)
	parameter ADDR_WIDTH = 32,              // width of address bus in bits
	parameter SELECT_WIDTH = (DATA_WIDTH/8) // width of word select bus (1, 2, 4, or 8)
)(
	input logic clk, rst );

	// shared bus intercon
	logic [ADDR_WIDTH-1:0]   adr;	// ADR_I() address input
	logic [DATA_WIDTH-1:0]   dat_i;	// DAT_I() data in
	logic [DATA_WIDTH-1:0]   dat_o;	// DAT_O() data out
	logic                    we;	// WE_I write enable input
	logic [SELECT_WIDTH-1:0] sel;	// SEL_I() select input
	logic                    stb;	// STB_I strobe input
	logic                    ack;	// ACK_O acknowledge output
	logic                    err;	// ERR_O error output
	logic                    rty;	// RTY_O retry output
	logic                    cyc;	// CYC_I cycle input
	//
	// slave -> intercon
	//
	logic [SLAVES-1:0] soack;	// ACK_O acknowledge output
	logic [SLAVES-1:0] soerr;	// ERR_O error output
	logic [SLAVES-1:0] sorty;	// RTY_O retry output	
	logic [DATA_WIDTH-1:0]sodat[SLAVES-1:0];// DAT_O() data out
	logic [SLAVES-1:0] sistb;	// STB strobe input
	// or after slaves			
	always_comb begin
		ack = | soack;
		err = | soerr;
		rty = | sorty;
	end
	//
	// master -> intercon
	//
	logic [ADDR_WIDTH-1:0] moadr [MASTERS-1:0];// ADR_I() address input
	logic [DATA_WIDTH-1:0] modat [MASTERS-1:0];// DAT_I() data in
	logic [SELECT_WIDTH-1:0]mosel[MASTERS-1:0];// SEL_I() select input
	logic [MASTERS-1:0] mostb;	// STB_I strobe input
	logic [MASTERS-1:0] mowe;	// WE_I write enable input
	logic [MASTERS-1:0] mocyc;
	logic [MASTERS-1:0] miack;
	logic [MASTERS-1:0] mierr;
	logic [MASTERS-1:0] mirty;	

	// grant encoded in arbiter
	logic [MASTERS-1:0] grant;
	// acmp encoded i n adress comparator
	logic [SLAVES-1:0] acmp;
	

	
//	    // upper 4 bits of granted master's adr_o select the slave
//    assign selected_slave = m2i_adr_i[ADDR_WIDTH*grant+ADDR_WIDTH-4+:4];
//
//    // distribute the stb_o signal only to the one slave
//    assign i2s_stb_o = m2i_stb_i[grant] << selected_slave;
	
	//generate masters and slaves
	genvar i;
	generate
		//define slaves
		for (i = 0; i < SLAVES; i++) begin : s
		
			always_comb begin
				sistb[i:i] = & {stb, cyc, acmp[i:i]};
			end
			
			Slave obj(
				.clk,
				.rst,
				.adr_i( adr ),
				.dat_i,
				.dat_o( sodat[i]   ),
				.sel_i( sel ),
				.we_i ( we ),
				.ack_o( soack[i:i] ),
				.err_o( soerr[i:i] ),
				.rty_o( sorty[i:i] ),
				.cyc_i( cyc        ),
				.stb_i( sistb[i:i] )
			);
		end
		// define masters
		for(i = 0; i < MASTERS; i++) begin : m	
		
			always_comb begin : m_a
				miack[i:i] = & { ack, grant[i:i] };
				mierr[i:i] = & { err, grant[i:i] };
				mirty[i:i] = & { rty, grant[i:i] };
			end
			
			Master obj(
				.clk,
				.rst,
				.adr_o( moadr[i]   ),
				.dat_i( dat_o      ),
				.dat_o( modat[i]   ),
				.sel_o( mosel[i]   ),
				.ack_i( miack[i:i] ),
				.err_i( mierr[i:i] ),
				.rty_i( mirty[i:i] ),
				.cyc_o( mocyc[i:i] ),
				.we_o ( mowe [i:i] ),
				.stb_o( mostb[i:i] )			
			);
		end
	endgenerate
	//multiplexed dat_o from masters
	Mux #(
		.INPUTS(MASTERS),
		.WIDTH(DATA_WIDTH)
	)
	mdat(
		.sel(grant),
		.in(modat),
		.out(dat_i)
	);
	//multiplexed adr_o output from master   
	Mux #(
		.INPUTS(MASTERS),
		.WIDTH(ADDR_WIDTH)
	)
	madr(
		.sel(grant),
		.in(moadr),
		.out(adr)
	);
//	//multiplexed data output from slave 
	Mux #(
		.INPUTS(SLAVES),
		.WIDTH(DATA_WIDTH)
	)
	sdat(
		.in(sodat),
		.out(dat_o)
	);
//	multiplexed sel output from master 
	Mux #(
		.INPUTS(MASTERS),
		.WIDTH(SELECT_WIDTH)
	)
	msel(
		.sel(grant),
		.in(mosel),
		.out(sel)
	);
	//multiplexed we output from master 
	Mux1 #(
		.INPUTS(MASTERS),
		.WIDTH(MASTERS)
	)
	mwe(
		.sel(grant),
		.in(mowe),
		.out(we)
	);
	
//	//multiplexed stb output from master 
	Mux1 #(
		.INPUTS(MASTERS),
		.WIDTH(MASTERS)
	)
	mstb(
		.sel(grant),
		.in(mostb),
		.out(stb)
	);

	// arbiter
	arbiter #(
		.PORTS(MASTERS)
	)
	arbiter(
		.clk,
		.grant,
		.request(mocyc),
		.grant_valid(cyc)
	);
	//adress comparator
	Adress_comparator #(
		.SLAVES(SLAVES),
		.MASTERS(MASTERS)
	)
	comparator(
		.adr,
		.acmp
	);
	
endmodule