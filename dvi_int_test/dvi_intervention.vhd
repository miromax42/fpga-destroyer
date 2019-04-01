library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity dvi_intervention is
  port (
  i_tmds0a,i_tmds0b,i_tmds1a,i_tmds1b,i_tmds2a,i_tmds2b,i_tmds_CLKa,i_tmds_CLKb: in std_logic;
  o_tmds0a,o_tmds0b,o_tmds1a,o_tmds1b,o_tmds2a,o_tmds2b,o_tmds_CLKa,o_tmds_CLKb: buffer std_logic
  );
end entity;

architecture arch of dvi_intervention is
  ------standart components------
  -----Signal declarations:--------------
	--SIGNAL clk25, clk250                        : STD_LOGIC;
	--SIGNAL Hsync, Vsync, Hactive, Vactive, dena : STD_LOGIC;
	--SIGNAL R, G, B                              : STD_LOGIC_VECTOR(7 DOWNTO 0);
	--SIGNAL control0, control1, control2         : STD_LOGIC_VECTOR(1 DOWNTO 0);
	--SIGNAL data0, data1, data2                  : STD_LOGIC_VECTOR(9 DOWNTO 0);
	-----1st component declaration:--------
	-----2nd component declaration:--------
	-----3rd component declaration:--------
	COMPONENT tmds_encoder IS
		PORT(
			din     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			control : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			clk25   : IN  STD_LOGIC;
			dena    : IN  STD_LOGIC;
			dout    : OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
	END COMPONENT;
	-----4th component declaration:--------
	COMPONENT serializer IS
		PORT(
			clk250 : IN  STD_LOGIC;
			din    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
			dout   : BUFFER STD_LOGIC);
	END COMPONENT;
	---------------------------------------

  component control_detector
generic (
  Ha : INTEGER := 96;
  Hb : INTEGER := 144;
  Hc : INTEGER := 784;
  Hd : INTEGER := 800;
  Va : INTEGER := 2;
  Vb : INTEGER := 35;
  Vc : INTEGER := 515;
  Vd : INTEGER := 525;
  Hs : integer := 200;
  Vs : integer := 200;
  He : integer := 300;
  Ve : integer := 300
);
port (
  clk25        : in  std_logic;
  din          : in  std_logic_vector(9 downto 0);
  Hsync        : BUFFER STD_LOGIC;
  Vsync        : OUT STD_LOGIC;
  Hactive      : BUFFER STD_LOGIC;
  Hactive_mini : BUFFER STD_LOGIC;
  Vactive      : BUFFER STD_LOGIC;
  Vactive_mini : BUFFER STD_LOGIC;
  dena_main    : buffer STD_LOGIC;
  dena_mini    : buffer STD_LOGIC;
  err          : buffer std_logic
);
end component control_detector;

  component antiserializer
port (
  clk250 : in  std_logic;
  err    : buffer  std_logic;
  din    : in  std_logic;
  dout   : out std_logic_vector(9 downto 0)
);
end component antiserializer;

  component pll25to250
  PORT (
  inclk0:in std_logic;
  c0:out std_logic
  );
  end component;

  Signal clk25:std_logic;
  signal clk250:std_logic;
  signal err:std_logic;
  signal Hsync,Vsync,Hactive,Vactive,Hactive_mini,Vactive_mini:std_logic;
  signal dena_main,dena_mini:std_logic;
  SIGNAL R, G, B                              : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL control0, control1, control2         : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL data0, data1, data2                  : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL new_data0, new_data1, new_data2                  : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL sw_data0, sw_data1, sw_data2                  : STD_LOGIC_VECTOR(9 DOWNTO 0);
------standart components------


begin
process(clk250)
begin
  if (dena_mini='1') THEN
    sw_data0<=data0;
    sw_data1<=data1;
    sw_data2<=data2;                  --
  else
    sw_data0 <= new_data0;
    sw_data1 <= new_data1;
    sw_data2 <= new_data2;
  end if;
end process;
  control0  <= Vsync & Hsync;
	control1  <= "00";
	control2  <= "00";
	clk25<=i_tmds_CLKa;
pll :pll25to250 port map(clk25,clk250);

control_0:control_detector port map(clk25,data0,Hsync,Vsync,Hactive,Hactive_mini,Vactive,Vactive_mini,dena_main,dena_mini,err);
aser_0:antiserializer port map(clk250,err,i_tmds0a,data0);
tmds0 : tmds_encoder PORT MAP("11110011", control0, clk25, dena_mini, new_data0);
serial0 : serializer PORT MAP(clk250, sw_data0, o_tmds0a);

aser_1:antiserializer port map(clk250,err,i_tmds1a,data1);
tmds1 : tmds_encoder PORT MAP("10010011", control1, clk25, dena_mini, new_data1);
serial1 : serializer PORT MAP(clk250, sw_data1, o_tmds1a);

aser_2:antiserializer port map(clk250,err,i_tmds2a,data2);
tmds2 : tmds_encoder PORT MAP("10011011", control2, clk25, dena_mini, new_data2);
serial2 : serializer PORT MAP(clk250, sw_data2, o_tmds2a);
o_tmds0b    <= NOT o_tmds0a;
o_tmds1b    <= NOT o_tmds1a;
o_tmds2b    <= NOT o_tmds2a;
o_tmds_clkb <= NOT o_tmds_clka;
end architecture;


