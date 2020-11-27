//App app(.pixel_clk(clk_25), .pixel_clk10(clk_250), .clk(clk_32));
//store it in an array bit[7:0] img[3][640][480] ; 3 is for R,G,B values , 640 and 480 is to match the pixel size.

module App #(
parameter DATA_WIDTH = 32,                    // width of data bus in bits (8, 16, 32, or 64)
parameter ADDR_WIDTH = 32,                    // width of address bus in bits
parameter SELECT_WIDTH = (DATA_WIDTH/8)       // width of word select bus (1, 2, 4, or 8)
)
	(
	input wire rst_in,
	input wire logic clk_50, 
	input wire logic clk_pix, 
	input wire logic clk_pix10, 
	input wire logic clk_audio,
	// These outputs go to your HDMI port
//	output logic [0:3] tmds_p,
//	output logic [0:3] tmds_n,
	// spi interface
	input  wire logic SD_MISO,
	output wire logic SD_CLK,
	output wire logic SD_MOSI,
	output wire logic SD_CS,
	// user interface
	input  logic [0:2]	button,
	output logic [0:3]	led
	);

	Intercom intercom	(
		.clk(clk_50),
		.rst(rst_in)
	);

//

endmodule
