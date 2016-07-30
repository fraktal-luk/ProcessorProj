----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:13:04 06/16/2016 
-- Design Name: 
-- Module Name:    UnitExec - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.ProcBasicDefs.all;
use work.Helpers.all;

use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;

use work.GeneralPipeDev.all;

use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcLogicExec.all;

use work.ProcComponents.all;


entity UnitExec is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  
			  flowResponseIQA: in FlowResponseSimple;
			  flowResponseIQB: in FlowResponseSimple;
			  flowResponseIQC: in FlowResponseSimple;
			  flowResponseIQD: in FlowResponseSimple;
				whichAcceptedCQ: in std_logic_vector(0 to 3);

				dataIQA: in InstructionState;
				dataIQB: in InstructionState;
				dataIQC: in InstructionState;
				dataIQD: in InstructionState;				

				intSig: in std_logic;
				--	eventCausingInt: in InstructionState;				
				lastCommitted: in InstructionState;
				lastCommittedNext: in InstructionState;		
		
				memLoadReady: in std_logic;
				memLoadValue: in Mword;
		-- Output
				memAddress: out Mword;
				memLoadAllow: out std_logic;
				memStoreAllow: out std_logic;
				memStoreValue: out Mword;
		
					--ilrIn: in Mword;
					--elrIn: in Mword;
					
					sysRegSelect: out slv5;
					sysRegIn: in MWord; 
															
				execAcceptingA: out std_logic;
				execAcceptingB: out std_logic;
				execAcceptingC: out std_logic;
				execAcceptingD: out std_logic;				
				selectedToCQ: out std_logic_vector(0 to 3);
				cqWhichSend: out std_logic_vector(0 to 3);
				
				execEventSignalOut: out std_logic;
				execCausingOut: out InstructionState;
				intCausingOut: out InstructionState;
				execPreEnds: out InstructionStateArray(0 to 3);
				execEnds: out InstructionStateArray(0 to 3)		
			  );
end UnitExec;



architecture Behavioral of UnitExec is
		signal resetSig, enSig: std_logic := '0';
			signal	execEventSignal, eventSignal: std_logic := '0';
			signal	execCausing, intCausing: InstructionState := defaultInstructionState;
			signal	activeCausing: InstructionState := defaultInstructionState;
			
			signal readyExecA, readyExecB, readyExecC, readyExecD: std_logic := '0';
			
		-- Internal signals
		signal execPrevResponses, execNextResponses: ExecResponseTable := (others=>(others=>'0'));
		
		signal execDrives: ExecDriveTable := (others=>(others=>'0')); 
		signal execResponses: ExecResponseTable := (others=>(others=>'0'));
		
		signal execData: ExecDataTable := (others=>defaultInstructionState);		
		signal execDataNext: ExecDataTable := (others=>defaultInstructionState);
		signal execDataNew: ExecDataTable := (others=>defaultInstructionState);	

		signal branchTarget, branchLink: Mword := (others => '0');
				signal btc: std_logic := '0';
				
	-- This isn't in IQ part! It's after Exec
	signal flowResponseAPost: FlowResponseSimple := (others=>'0');					
	signal flowResponseBPost, flowResponseCPost, flowResponseDPost: FlowResponseSimple
					:= (others=>'0');

	constant HAS_RESET_EXEC: std_logic := '1';
	constant HAS_EN_EXEC: std_logic := '1';	
	
	signal aluAOut, aguCOut: InstructionState := defaultInstructionState;
	signal lsOut: InstructionState := defaultInstructionState;
	
	--signal sysRegArray: MwordArray(0 to 31) := (others => (others => '0'));
	signal sysRegValue: Mword := (others => '0');
	signal sysRegReadSel, sysRegWriteSel: slv5 := (others => '0');
begin		
		resetSig <= reset and HAS_RESET_EXEC;
		enSig <= en or not HAS_EN_EXEC; 

		execPrevResponses <= getExecPrevResponses(execResponses,
										flowResponseIQA, flowResponseIQB, flowResponseIQC, flowResponseIQD);
		execNextResponses <= getExecNextResponses(execResponses,
											flowResponseAPost, flowResponseBPost, flowResponseCPost, flowResponseDPost);
			
		EXEC_DRIVE_ASSIGN: for s in ExecStages'left to ExecStages'right generate
			execDrives(s).prevSending <= execPrevResponses(s).sending;
			execDrives(s).nextAccepting <= execNextResponses(s).accepting;				
		end generate;				
			
		CALC_TARGET: block
			signal aai0, aai1, aai2: Mword := (others => '0');
			signal lai0, lai1: Mword := (others => '0');
		begin	
			aai0 <= dataIQD.basicInfo.ip;
			aai1 <= dataIQD.constantArgs.imm;
			lai0 <= dataIQD.basicInfo.ip;
			lai1 <= getAddressIncrement(dataIQD);
			
			TARGET_ADDER: entity work.VerilogALU32 port map(
				clk => '0', reset => '0', en => '0', allow => '0',
				funcSelect => "000001", -- addition
				dataIn0 => aai0,
				dataIn1 => aai1,
				dataIn2 => aai2, -- Ignored
				c0 => "00000", c1 => "00000", 
				dataOut0 => open, carryOut => open, exceptionOut => open, 
				dataOut0Pre => branchTarget, carryOutPre => open, exceptionOutPre => open
			);

			LINK_ADDER: entity work.VerilogALU32 port map(
				clk => '0', reset => '0', en => '0', allow => '0',
				funcSelect => "000001", -- addition
				dataIn0 => lai0,
				dataIn1 => lai1,
				dataIn2 => aai2, -- Ignored
				c0 => "00000", c1 => "00000", 
				dataOut0 => open, carryOut => open, exceptionOut => open, 
				dataOut0Pre => branchLink, carryOutPre => open, exceptionOutPre => open
			);				
		end block;			
		
			-- TODO: system reg addressing
			sysRegReadSel <= dataIQD.constantArgs.c1;  -- TEMP?
			--sysRegWriteSel <= dataIQD.constantArgs.c1; -- TEMP
			--sysRegValue <= sysRegArray(slv2u(sysRegReadSel));
		
			--sysRegArray(2) <= elrIn;
			--sysRegArray(3) <= ilrIn;
		
				sysRegSelect <= sysRegReadSel;
				sysRegValue <= sysRegIn; 
		
		execDataNew <= (	ExecA0 => --execLogicXor(dataIQA), -- dataOutIQA,
											 aluAOut,	
								ExecB0 => dataIQB,
								ExecB1 => execData(ExecB0), ExecB2 => execLogicXor(execData(ExecB1)),
								ExecC0 => --dataIQC,
											 aguCOut,	
								ExecC1 => execData(ExecC0), ExecC2 => --execLogicXor(execData(ExecC1)),
																					lsOut,
								ExecD0 => --basicBranch(dataIQD),
											 basicBranch(setInstructionTarget(dataIQD, branchTarget),
																sysRegValue, branchLink),
								others => defaultInstructionState);
			-- CAREFUL! Here we must somehow include actual exec operations!				
			--execDataNew <= getExecDataNew(execDataUpdated, dataASel, dataBSel, dataCSel, dataDSel);											
		
				-- ;
				--btc <= '1' when branchTarget = dataOutIQD.target else '0';
		
		-- Automatic exec data passing
		EXEC_DATA_NEXT: for s in ExecStages'left to ExecStages'right generate
			execDataNext(s) <= stageSimpleNext(execData(s), execDataNew(s),
					execResponses(s).living, execResponses(s).sending, execDrives(s).prevSending);	
		end generate;
			
		EXEC_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enSig = '1' then	
					execData <= execDataNext;					
				end if;
			end if;
		end process;	

		-- Stage logic for all exec stages
		EXEC_LOGIC_SLOTS: for s in ExecStages'left to ExecStages'right generate
			EXEC_SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
					clk => clk,
					reset => resetSig,
					en => enSig,
					flowDrive => execDrives(s),
					flowResponse => execResponses(s)
				);		
		end generate;	

		
		EXEC_UNIT_A: block
			signal a0, a1, a2, aluRes: Mword := (others => '0');
			signal c0, c1: slv5 := (others => '0');
			signal exc: std_logic_vector(3 downto 0) := (others => '0');
			signal carry: std_logic := '0';
			signal funcSel: slv6 := (others => '0');
		begin
			a0 <= dataIQA.argValues.arg0;
			a1 <= dataIQA.argValues.arg1;
			a2 <= dataIQA.argValues.arg2;			
			c0 <= dataIQA.constantArgs.c0;
			c1 <= dataIQA.constantArgs.c1;
		
			with dataIQA.operation.func select
				funcSel <=
					"000001"	when arithAdd,
					"000010"	when arithSub,
					"000011"	when arithShra,
					"000100"	when logicAnd,
					"000101"	when logicOr,
					"000110"	when logicShl,
					"000111"	when logicShrl,
					--"001000"	when logicXor,					
					"000000"	when others;
		
			MAIN_ALU: entity work.VerilogALU32
			port map(
				clk => '0', reset => '0', en => '0', allow => '0',
				funcSelect => funcSel,
				dataIn0 => a0,
				dataIn1 => a1,
				dataIn2 => a2,
				c0 => c0,
				c1 => c1,
				dataOut0 => open,
				carryOut => open,
				exceptionOut => open,
				dataOut0Pre => aluRes,
				carryOutPre => carry,
				exceptionOutPre => exc
			);
	
			aluAOut <= setExecState(dataIQA, aluRes, carry, exc);
		end block;

		AGU_C: block
			signal aai0, aai1, aai2, memAddress: Mword := (others => '0');
		begin	
			aai0 <= dataIQC.basicInfo.ip;
			aai1 <= dataIQC.constantArgs.imm;
			
			ADDRESS_ADDER: entity work.VerilogALU32 port map(
				clk => '0', reset => '0', en => '0', allow => '0',
				funcSelect => "000001", -- addition
				dataIn0 => aai0,
				dataIn1 => aai1,
				dataIn2 => aai2, -- Ignored
				c0 => "00000", c1 => "00000", 
				dataOut0 => open, carryOut => open, exceptionOut => open, 
				dataOut0Pre => memAddress, carryOutPre => open, exceptionOutPre => open
			);
			
			aguCOut <= setExecState(dataIQC, memAddress, '0', "0000");				
		end block;	
		
		memLoadAllow <= execResponses(ExecC0).full when execData(ExecC0).operation.func = load else '0';
		memStoreAllow <= execResponses(ExecC0).full when execData(ExecC0).operation.func = store else '0';
		
		lsOut <= setExecState(execData(ExecC1), memLoadValue, '0', "0000");
		
-------------------------------------------------------------------------------------------------
	-- Event selection
	
	-- Exec/int events:
		eventSignal <= intSig or execEventSignal;
									
			execEventSignal <= (execData(ExecD0).controlInfo.newEvent and execResponses(ExecD0).isNew);
	
		-- NOTE: alternatively,here would be lastCommittedNext, and instructions in CQ certain to be committed in
		--			nearest cycle would be spared from killing (CAREFUL: needed collaboration from CQ killer)
		intCausing <= setInterrupt(lastCommitted, intSig, "00000000");		
		execCausing <= execData(ExecD0);
		activeCausing <= intCausing when intSig = '1'
						-- lastCommittedNext when intSig = '1' -- NOTE: this - for sparing "almost committed"		
						else execCausing; --	execData(ExecD0) when execEventSignal = '1' 
						--else	defaultInstructionState;  -- CHECK: maybe this option not needed, simpler without it?	
				
		-- CAREFUL! In all automatic blocks for exec, remember about correct range of stages!
		EXEC_KILL: for s in ExecStages'left to ExecStages'right generate
			signal before: std_logic;
			signal a, b: std_logic_vector(7 downto 0);
		begin
			a <= activeCausing.numberTag;
			b <= execData(s).numberTag;
			EXEC_KILLER: entity work.CompareBefore8 port map(
				inA => a, 
				inB => b, 
				outC => before
			);		
			execDrives(s).kill <= before and eventSignal; 	
		end generate;
	
			memAddress <= execData(ExecC0).result;
			memStoreValue <= execData(ExecC0).argValues.arg2;
	
		-- Interface between exec and CQ
		readyExecA <= execResponses(ExecA0).living;
		readyExecB <= execResponses(ExecB2).living;
		readyExecC <= execResponses(ExecC2).living;
		readyExecD <= execResponses(ExecD0).living;	
	
		flowResponseAPost.accepting <= whichAcceptedCQ(0);
		flowResponseBPost.accepting <= whichAcceptedCQ(1);
		flowResponseCPost.accepting <= whichAcceptedCQ(2);
		flowResponseDPost.accepting <= whichAcceptedCQ(3);	
	
		execAcceptingA <= execResponses(ExecA0).accepting;
		execAcceptingB <= execResponses(ExecB0).accepting;
		execAcceptingC <= execResponses(ExecC0).accepting;
		execAcceptingD <= execResponses(ExecD0).accepting;	
	
		selectedToCQ <= (0 => readyExecA, 1 => readyExecB, 2 => readyExecC, 3 => readyExecD, others=>'0');
		cqWhichSend <= (0 => execResponses(ExecA0).sending, 1 => execResponses(ExecB2).sending,
							 2 => execResponses(ExecC2).sending, 3 =>	execResponses(ExecD0).sending,
								others=>'0');
		execEnds <= (	0=> clearTempControlInfoSimple(execData(ExecA0)),
							1=> clearTempControlInfoSimple(execData(ExecB2)),
							2=> clearTempControlInfoSimple(execData(ExecC2)),
							3=> clearTempControlInfoSimple(execData(ExecD0)),
						others=> defaultInstructionState);
		execPreEnds <= (1=> execData(ExecB1), 2=> execData(ExecC1),
						others=> defaultInstructionState);											
		
	execEventSignalOut <= eventSignal;
	execCausingOut <= activeCausing;
	intCausingOut <= intCausing;
	
end Behavioral;

