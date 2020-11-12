//App app(.pixel_clk(clk_25), .pixel_clk10(clk_250), .clk(clk_32));
//store it in an array bit[7:0] img[3][640][480] ; 3 is for R,G,B values , 640 and 480 is to match the pixel size.

module App (
	input wire rst_in,
	input wire logic clk_50, 
	input wire logic clk_pix, 
	input wire logic clk_pix10, 
	input wire logic clk_audio,
	// These outputs go to your HDMI port
	output logic [0:3] tmds_p,
	output logic [0:3] tmds_n,
	// spi interface
	input  wire logic SD_MISO,
	output wire logic SD_CLK,
	output wire logic SD_MOSI,
	output wire logic SD_CS,
	// user interface
	input  logic [0:2]	button,
	output logic [0:3]	led
	);


	// picture 
	logic [9:0] cx, cy, screen_start_x, screen_start_y, frame_width, frame_height, screen_width, screen_height;

//	always @(posedge clk_audio)
//		audio_sample_word <= '{audio_sample_word[0] + 16'sd1, audio_sample_word[1] - 16'sd1};
	//---------------------
	//generate picture
	//---------------------
	logic [23:0] rgb = 24'd0;
	always_ff @(posedge clk_pix)
		begin
			rgb[23:16] <= {cx[5:0] & {6{cy[4:3]==~cx[4:3]}}, 2'b00};
			rgb[15:8] <= cx[7:0] & {8{cy[6]}};
			rgb[7:0] <= cy[7:0];
		end
		
	//generate sound
//	logic [15:0] audio_sample_word [1:0] = '{16'sd0, 16'sd0};
	localparam AUDIO_BIT_WIDTH = 16;
	localparam AUDIO_RATE = 44100;
	localparam WAVE_RATE = 441;

	logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word [1:0];
	logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word_dampened; // This is to avoid giving you a heart attack -- it'll be really loud if it uses the full dynamic range.
	assign audio_sample_word_dampened = audio_sample_word [1] >> 9;

	sawtooth #(
		.AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH), 
		.SAMPLE_RATE(AUDIO_RATE), 
		.WAVE_RATE(WAVE_RATE)
	) 
	sawtooth (
		.clk_audio, 
		.audio_sample_word
	);

		
	//---------------------
	// hdmi interface
	//---------------------


	hdmi #(
		.VIDEO_ID_CODE(1), 
		.AUDIO_RATE(AUDIO_RATE), 
		.AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH)
	)
	hdmi_int
	(
		.clk_pixel_x10(clk_pix10),
		.clk_pixel(clk_pix),
		.clk_audio(clk_audio),
		.rgb, // vstup pre video data
		.audio_sample_word,

		// These outputs go to your HDMI port
		.tmds_p({tmds_p[2],tmds_p[1],tmds_p[0]}),
		.tmds_clock_p(tmds_p[3]),
		.tmds_n({tmds_n[2],tmds_n[1],tmds_n[0]}),
		.tmds_clock_n(tmds_n[3]),

		// All outputs below this line stay inside the FPGA
		// They are used (by you) to pick the color each pixel should have
		// i.e. always_ff @(posedge pixel_clk) rgb <= {8'd0, 8'(cx), 8'(cy)};
		.cx,
		.cy,

		// the screen is at the bottom right corner of the frame, namely:
		// frame_width = screen_start_x + screen_width
		// frame_height = screen_start_y + screen_height
		.frame_width,
		.frame_height,
		.screen_width,
		.screen_height,
		.screen_start_x,
		.screen_start_y
	);	

	//---------------------
	// sdcard
	//---------------------
	wire       outreq;    // when outreq=1, a byte of file content is read out from outbyte
	wire [7:0] outbyte;   // a byte of file content

	wire [3:0] sdcardstate;
	wire [1:0] sdcardtype;
	wire [2:0] fatstate;
	wire [1:0] filesystemtype;
	wire       file_found;

	//assign SD_RESET = 1'b0;
	assign SD_RESET = button[1];
	
	//led 3 zobrazi outreq
	assign led[1] = file_found;

	// For input and output definitions of this module, see sd_file_reader.sv
	sd_file_reader #(
		 .FILE_NAME      ( "01_640x480.png"  ), // file to read, ignore Upper and Lower Case
														 // For example, if you want to read a file named HeLLo123.txt in the SD card,
														 // the parameter here can be hello123.TXT, HELLO123.txt or HEllo123.Txt
		 
		 .SPI_CLK_DIV    ( 100            )  // SD spi_clk freq = clk freq/(2*SPI_CLK_DIV)
														 // modify SPI_CLK_DIV to change the SPI speed
														 // for example, when clk=100MHz, SPI_CLK_DIV=100,then spi_clk=100MHz/(2*100)=500kHz
														 // 500kHz is a typical SPI speed for SDcard
	) sd_file_reader_inst (
		 .clk            ( clk_50      ),
		 .rst_n          ( SD_RESET         ),  // rst_n active low, re-scan and re-read SDcard by reset
		 
		 // signals connect to SD bus
		 .spi_miso       ( SD_MISO    ),
		 .spi_mosi       ( SD_MOSI    ),
		 .spi_clk        ( SD_CLK     ),
		 .spi_cs_n       ( SD_CS    ),
		 
		 // display information on 12bit LED
		 .sdcardstate    ( sdcardstate ),
		 .sdcardtype     ( sdcardtype ),  // 0=Unknown, 1=SDv1.1 , 2=SDv2 , 3=SDHCv2
		 .fatstate       ( fatstate ),  // 3'd6 = DONE
		 .filesystemtype ( filesystemtype ),  // 0=Unknown, 1=invalid, 2=FAT16, 3=FAT32
		 .file_found     ( file_found ),  // 0=file not found, 1=file found
		 
		 // file content output interface
		 .outreq         ( outreq         ),
		 .outbyte        ( outbyte        )
	);


endmodule
