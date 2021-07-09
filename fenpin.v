module fenpin ( clk,clk_450KHz,rst );//25MHZ分频至450KHZ
input            clk ;        //系统时钟
input            rst ;        //系统复位 
output			 clk_450KHz;
reg     [5:0]    psc_450KHz;	
reg  		     reg_450KHz = 1'b1;


always @ (posedge clk or negedge rst) //芯片时钟信号
begin
	if ( rst == 1'b0 ) begin
		psc_450KHz <= 6'd0;
		reg_450KHz <= 1'b0;
	end
	else begin
		psc_450KHz <= psc_450KHz + 1'b1;
		if ( ( psc_450KHz >= 6'd56) && ( rst == 1'b1 ) ) begin
			psc_450KHz <= 6'd0;
			reg_450KHz = ~reg_450KHz;
		end
	end			
end

assign  clk_450KHz = reg_450KHz; 
endmodule
