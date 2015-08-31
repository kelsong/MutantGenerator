module b06(
	input clock,
	input reset,
	input eql,
	input cont_eql,
	output reg[2:1] cc_mux,
	output reg[2:1] uscite,
	output reg enable_count,
	output reg ackout
	);
	
`define s_init 		3'b000
`define s_wait		3'b001
`define s_enin 		3'b010
`define s_enin_w 	3'b011
`define s_intr 		3'b100
`define s_intr_1 	3'b101
`define s_intr_w 	3'b110

reg[2:0] curr_state;


always @ (posedge clock)
begin
	if (reset)//InstPt 0
	begin
		curr_state <= `s_init;
		cc_mux <= 2'b00;
		enable_count <= 1'b0;
		ackout <= 1'b0;
		uscite <= 2'b00;
	end
	else //InstPt 23
	begin 
		if (cont_eql) //InstPt 1
		begin
			ackout <= 1'b0;
			enable_count <= 1'b0;
		end
		else //InstPt 2
		begin
			ackout <= 1'b1;
			enable_count <= 1'b1;
		end
		
		case (curr_state)
			`s_init: //instPt 3
			begin
				cc_mux <= 2'b01;
				uscite <= 2'b01;
				curr_state <= `s_wait;
			end
			
			`s_wait: //instPt 6
			begin
				if (eql) //InstPt 4
				begin
					uscite <= 2'b00;
					cc_mux <= 2'b11;
					curr_state <= `s_enin;
				end
				else //InstPt 5
				begin
					uscite <= 2'b01;
					cc_mux <= 2'b10;
					curr_state <= `s_intr_1;
				end
			end
			
			`s_intr_1: //InstPt 9
			begin
				if (eql) //InstPt 7
				begin
					uscite <= 2'b00;
					cc_mux <= 2'b11;
					curr_state <= `s_intr;
				end
				else //InstPt 8
				begin
					uscite <= 2'b01;
					cc_mux <= 2'b01;
					curr_state <= `s_wait;
				end
			end
			
			`s_enin: //InstPt12
			begin
				if (eql) //InstPt 10
				begin
					uscite <= 2'b00;
					cc_mux <= 2'b11;
					curr_state <= `s_enin;
				end
				else //InstPt 11
				begin
					uscite <= 2'b01;
					ackout <= 1'b1;
					enable_count <= 1'b1;
					cc_mux <= 2'b01;
					curr_state <= `s_enin_w;
				end
			end
			
			`s_enin_w: //InstPt 15
			begin
				if (eql) //InstPt 13
				begin
					uscite <= 2'b01;
					cc_mux <= 2'b01;
					curr_state <= `s_enin_w;
				end
				else //InstPt 14
				begin
					uscite <= 2'b01;
					cc_mux <= 2'b01;
					curr_state <= `s_wait;
				end
			end
			
			`s_intr: //InstPt 18
			begin
				if (eql) //InstPt 16
				begin
					uscite <= 2'b00;
					cc_mux <= 2'b11;
					curr_state <= `s_intr;
				end
				else //InstPt 17
				begin
					uscite <= 2'b11;
					cc_mux <= 2'b10;
					curr_state <= `s_intr_w;
				end
			end
			
			`s_intr_w: //InstPt 21
			begin
				if (eql) //InstPt 19
				begin
					uscite <= 2'b11;
					cc_mux <= 2'b10;
					curr_state <= `s_intr_w;
				end
				else //InstPt 20
				begin
					uscite <= 2'b01;
					cc_mux <= 2'b01;
					curr_state <= `s_wait;
				end
			end
			
			default: //InstPt 22
				curr_state <= `s_init;
		endcase
	end
end
	
endmodule
