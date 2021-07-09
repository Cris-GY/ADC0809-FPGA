module kongzhi ( ALE,OE,DATA,EOC,clk,START,rst,ADC_DATAOUT,oe_r,testled );

input            EOC ;      // end of conversion ADC0809转换完成信号标志
input            clk ;        //系统时钟
input            rst ;        //系统复位 
input    [7:0]    DATA ;     //ADC0809传进来的转换数据


output          ALE ; // address lock enable FPGA给ADC0809的地址锁存信号
output          OE ;                      //FPGA给ADC0809的使能信号

output          START ;                  //控制ADC0809转换开始信号
output    [7:0]    ADC_DATAOUT ;
output    oe_r ;
output    testled;

parameter   st0 = 3'b000, //一轮完整进程需要的步骤
            st1 = 3'b001,
            st2 = 3'b010,
            st3 = 3'b011,
            st4 = 3'b100,
            st5 = 3'b101,
            st6 = 3'b110;


reg    [2:0]    p_state = 3'b000  ;
reg    [7:0]    reg_adc; //ADC数据暂存寄存器            
reg    [2:0]    n_state = 3'b000 ;            
reg             ale_r    ; //地址锁存 上升沿有效
reg             start_r    ;  //转换开始 上升沿有效  
reg             oe_r    ; //输出使能 上升沿有效
reg     [7:0]    prescaler ;//分频因子    
reg			     ledgreen = 1'b0;




always @ (posedge clk or negedge rst)
begin
	if ( rst== 1'b0 ) begin
		p_state <= st0    ;     //步骤清零
        prescaler <= 8'b0  ;		//分频器清零
    end
    else    begin 
        prescaler <= prescaler + 1'b1;
        if ( ( prescaler >= 8'b0011_1000)/* && ( rst == 1'b1 )*/ ) begin //8'b0100_0010仅提高易读性
			prescaler <= 8'b0;
            p_state <= n_state;      //#1延迟实际意义不大 是一种“神话”
        end      
    end
end     


always @ ( EOC ,p_state ,rst ) //EOC end of conversion 敏感信号 电平触发 EOC与p_state发生变化即触发模块
begin
	if ( rst== 1'b0 ) begin
	reg_adc = 8'b0;
	ledgreen	<= 1'b1;
	end
	else
	begin
	case ( p_state ) 
		st0 :begin   //第零步 全部恢复默认状态
            ale_r <= #1 1'b0;
             start_r <= #1 1'b0;
            oe_r <= #1 1'b0;
            n_state <=#1 st1;
				ledgreen	<= 1'b0;
        end 
        st1 :begin  //第一步 地址锁存端上拉
            ale_r <= #1 1'b1;
             start_r <= #1 1'b0;
            oe_r <= #1 1'b0;
            n_state <=#1 st2;  
        end
        st2 :begin   //第二步：地址锁存下拉，转换启动上拉
            ale_r <= #1 1'b0;
             start_r <= #1 1'b1;    
            oe_r <= #1 1'b0;
            n_state <=#1 st3; 
        end
        st3 :begin  //第三步 转换启动下拉，开始进行转换
            ale_r <= #1 1'b0;
             start_r <= #1 1'b0;    
            oe_r <= #1 1'b0; 
            if ( EOC == 1'b1 ) //等待转换启动的下降沿
                n_state <=#1 st3;  
            else
                n_state <=#1 st4; //出现下降沿 进入下一步
            end      
        st4 :begin
             ale_r <= #1 1'b0;
             start_r <= #1 1'b0;    
            oe_r <= #1 1'b0; 
            if ( EOC == 1'b0 )
				    n_state <=#1 st4;  //等待转换结束的上升沿
            else
				    n_state <=#1 st5;  //上升沿出现，转换完成，进入下一步
        end      
        st5 :begin
             ale_r <= #1 1'b0;
             start_r <= #1 1'b0;    
            oe_r <= #1 1'b1;   //输出转换数据使能
				ledgreen	<= 1'b1;
            n_state <=#1 st6; 
        end     
        st6 :begin
             ale_r <= #1 1'b0;
             start_r <= #1 1'b0;    
            oe_r <= #1 1'b1; 
          //reg_adc <=#1 (DATA*(7'd100))/(6'd51); //输出数据给到寄存器 需要进行一些处理
				reg_adc <= DATA ; //输出数据给到寄存器 需要进行一些处理
			 //	data = DATA ;
            n_state <=#1 st0; //一轮结束
        end    
        default :begin
             ale_r <= #1 1'b0; //OE下降沿 结束输出
             start_r <= #1 1'b0;    
            oe_r <= #1 1'b0; 
            n_state <=#1 st0; 
        end
	endcase
	end
        
end    

assign	ALE = ale_r    ;        
assign  OE = oe_r     ;
assign  START = start_r     ;
assign	testled = ledgreen; 
assign   ADC_DATAOUT = reg_adc;

endmodule
    
