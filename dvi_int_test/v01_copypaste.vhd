-----Image generator:-------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
----------------------------------------------------------------------
entity image_generator is
  port(
    red_switch, green_switch, blue_switch : in  std_logic;
    Hsync, Vsync, Vactive, dena           : in  std_logic;
    R, G, B                               : out std_logic_vector(7 downto 0));
end image_generator;
----------------------------------------------------------------------
architecture image_generator of image_generator is
begin
  process(Hsync, Vsync, dena, red_switch, green_switch, blue_switch)
    variable line_counter : integer range 0 to 480;
  begin
    -----Create pointer to LCD rows:-----
    if (Vsync = '0') then
      line_counter := 0;
    elsif (Hsync'event and Hsync = '1') then
      if (Vactive = '1') then
        line_counter := line_counter + 1;
      end if;
    end if;
    -----Create image:-------------------
    if (dena = '1') then
      if (line_counter = 1) then
        R <= (others => '1');
        G <= (others => '0');
        B <= (others => '0');
      elsif (line_counter = 2 or line_counter = 3) then
        R <= (others => '0');
        G <= (others => '1');
        B <= (others => '0');
      elsif (line_counter > 3 and line_counter <= 6) then
        R <= (others => '0');
        G <= (others => '0');
        B <= (others => '1');
      else
        R <= (others => red_switch);
        G <= (others => green_switch);
        B <= (others => blue_switch);
      end if;
    else
      R <= (others => '0');
      G <= (others => '0');
      B <= (others => '0');
    end if;
  end process;
end image_generator;
----------------------------------------------------------------------
-----Control generator:--------------------------------------
library ieee;
use ieee.std_logic_1164.all;
-------------------------------------------------------------
entity control_generator is
  generic(
    Ha : integer := 96;                 --Hpulse
    Hb : integer := 144;                --Hpulse+HBP
    Hc : integer := 784;                --Hpulse+HBP+Hactive
    Hd : integer := 800;                --Hpulse+HBP+Hactive+HFP
    Va : integer := 2;                  --Vpulse
    Vb : integer := 35;                 --Vpulse+VBP
    Vc : integer := 515;                --Vpulse+VBP+Vactive
    Vd : integer := 525);               --Vpulse+VBP+Vactive+VFP
  port(
    clk50   : in     std_logic;         --System clock (50MHz)
    clk25   : buffer std_logic;         --TMDS clock (25MHz)
    clk250  : buffer std_logic;         --Tx clock (250MHz)
    Hsync   : buffer std_logic;         --Horizontal sync
    Vsync   : out    std_logic;         --Vertical sync
    Hactive : buffer std_logic;         --Active portion of Hsync
    Vactive : buffer std_logic;         --Active portion of Vsync
    dena    : out    std_logic);        --Display enable
end control_generator;
-------------------------------------------------------------
architecture control_generator of control_generator is
  component pll50to250 is
    port(
      inclk0 : in     std_logic;
      c0     : buffer std_logic);
  end component;
begin
  -----Generation of clk250:-------------
  pll228 : pll50to250 port map(clk50, clk250);
  -----Generation of clk25:--------------
  ---Option 1: From clk50
  process(clk50)
  begin
    if (clk50'event and clk50 = '1') then
      clk25 <= not clk25;
    end if;
  end process;
  ---Option 2: From clk250
  --PROCESS (clk250)
  -- VARIABLE count: INTEGER RANGE 0 TO 5;
  --BEGIN
  -- IF (clk250'EVENT AND clk250='1') THEN
  -- count := count + 1;
  -- IF (count=5) THEN
  -- clk25 <= NOT clk25;
  -- count := 0;
  -- END IF;
  -- END IF;
  --END PROCESS;
  ---Horizontal signals generation:----
  process(clk25)
    variable Hcount : integer range 0 to Hd;
  begin
    if (clk25'event and clk25 = '1') then
      Hcount := Hcount + 1;
      if (Hcount = Ha) then
        Hsync <= '1';
      elsif (Hcount = Hb) then
        Hactive <= '1';
      elsif (Hcount = Hc) then
        Hactive <= '0';
      elsif (Hcount = Hd) then
        Hsync  <= '0';
        Hcount := 0;
      end if;
    end if;
  end process;
  -----Vertical signals generation:------
  process(Hsync)
    variable Vcount : integer range 0 to Vd;
  begin
    if (Hsync'event and Hsync = '0') then
      Vcount := Vcount + 1;
      if (Vcount = Va) then
        Vsync <= '1';
      elsif (Vcount = Vb) then
        Vactive <= '1';
      elsif (Vcount = Vc) then
        Vactive <= '0';
      elsif (Vcount = Vd) then
        Vsync  <= '0';
        Vcount := 0;
      end if;
    end if;
  end process;
  -----Display-enable generation:--------
  dena <= Hactive and Vactive;
end control_generator;
-------------------------------------------------------------

-----TMDS encoder:------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
------------------------------------------------------------------
entity tmds_encoder is
  port(
    din     : in  std_logic_vector(7 downto 0);   --pixel data
    control : in  std_logic_vector(1 downto 0);   --control data
    clk25   : in  std_logic;                      --clock
    dena    : in  std_logic;                      --display enable
    dout    : out std_logic_vector(9 downto 0));  --output data
end tmds_encoder;
------------------------------------------------------------------
architecture tmds_encoder of tmds_encoder is
  signal x     : std_logic_vector(8 downto 0);    --internal vector
  signal onesX : integer range 0 to 8;            --# of '1's in x
  signal onesD : integer range 0 to 8;            --# of '1's in din
  signal disp  : integer range -16 to 15;         --disparity
begin
  -----Computes number of '1's in din:--------
  process(din)
    variable counterD : integer range 0 to 8;
  begin
    counterD := 0;
    for i in 0 to 7 loop
      if (din(i) = '1') then
        counterD := counterD + 1;
      end if;
    end loop;
    onesD <= counterD;
  end process;
  -----Produces the internal vector x:-------
  process(din, onesD)
  begin
    x(0) <= din(0);
    if (onesD > 4 or (onesD = 4 and din(0) = '0')) then
      x(1) <= din(1) xnor x(0);
      x(2) <= din(2) xnor x(1);
      x(3) <= din(3) xnor x(2);
      x(4) <= din(4) xnor x(3);
      x(5) <= din(5) xnor x(4);
      x(6) <= din(6) xnor x(5);
      x(7) <= din(7) xnor x(6);
      x(8) <= '0';
    else
      x(1) <= din(1) xor x(0);
      x(2) <= din(2) xor x(1);
      x(3) <= din(3) xor x(2);
      x(4) <= din(4) xor x(3);
      x(5) <= din(5) xor x(4);
      x(6) <= din(6) xor x(5);
      x(7) <= din(7) xor x(6);
      x(8) <= '1';
    end if;
  end process;
  -----Computes the number of '1's in x:-----
  process(x)
    variable counterX : integer range 0 to 8;
  begin
    counterX := 0;
    for i in 0 to 7 loop
      if (x(i) = '1') then
        counterX := counterX + 1;
      end if;
    end loop;
    onesX <= counterX;
  end process;
  -----Produces output vector and new disparity:--
  process(disp, x, onesX, dena, control, clk25)
    variable disp_new : integer range -31 to 31;
  begin
    if (dena = '1') then
      dout(8) <= x(8);
      if (disp = 0 or onesX = 4) then
        dout(9) <= not x(8);
        if (x(8) = '0') then
          dout(7 downto 0) <= not x(7 downto 0);
          disp_new         := disp - 2 * onesX + 8;
        else
          dout(7 downto 0) <= x(7 downto 0);
          disp_new         := disp + 2 * onesX - 8;
        end if;
      else
        if ((disp > 0 and onesX > 4) or (disp < 0 and onesX < 4)) then
          dout(9)          <= '1';
          dout(7 downto 0) <= not x(7 downto 0);
          if (x(8) = '0') then
            disp_new := disp - 2 * onesX + 8;
          else
            disp_new := disp - 2 * onesX + 10;
          end if;
        else
          dout(9)          <= '0';
          dout(7 downto 0) <= x(7 downto 0);
          if (x(8) = '0') then
            disp_new := disp + 2 * onesX - 10;
          else
            disp_new := disp + 2 * onesX - 8;
          end if;
        end if;
      end if;
    else
      disp_new := 0;
      if (control = "00") then
        dout <= "1101010100";
      elsif (control = "01") then
        dout <= "0010101011";
      elsif (control = "10") then
        dout <= "0101010100";
      else
        dout <= "1010101011";
      end if;
    end if;
    if (clk25'event and clk25 = '1') then
      disp <= disp_new;
    end if;
  end process;
end tmds_encoder;
------------------------------------------------------------------

-----Serializer:---------------------------------
library ieee;
use ieee.std_logic_1164.all;
-------------------------------------------------
entity serializer is
  port(clk250 : in     std_logic;
       din    : in     std_logic_vector(9 downto 0);
       dout   : buffer std_logic);
end serializer;
-------------------------------------------------
architecture serializer of serializer is
  signal internal : std_logic_vector(9 downto 0);
begin
  process(clk250)
    variable count : integer range 0 to 10;
  begin
    if (clk250'event and clk250 = '1') then
      count := count + 1;
      if (count = 9) then
        internal <= din;
      elsif (count = 10) then
        count := 0;
      end if;
      dout <= internal(count);
    end if;
  end process;
end serializer;
-------------------------------------------------

-----Main code:------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
---------------------------------------------------------------------
entity dvi_stripes is
  port(
    clk50                                 : in     std_logic;  --50MHz system clock
    red_switch, green_switch, blue_switch : in     std_logic;
    tmds0a, tmds0b                        : buffer std_logic;  --TMDS0+, TMDS0-
    tmds1a, tmds1b                        : buffer std_logic;  --TMDS1+, TMDS1-
    tmds2a, tmds2b                        : buffer std_logic;  --TMDS2+, TMDS2-
    tmds_clka, tmds_clkb                  : out    std_logic);  --TMDS_clk+,TMDS_clk-
end dvi_stripes;
---------------------------------------------------------------------
architecture dvi of dvi_stripes is
  -----Signal declarations:--------------
  signal clk25, clk250                        : std_logic;
  signal Hsync, Vsync, Hactive, Vactive, dena : std_logic;
  signal R, G, B                              : std_logic_vector(7 downto 0);
  signal control0, control1, control2         : std_logic_vector(1 downto 0);
  signal data0, data1, data2                  : std_logic_vector(9 downto 0);
  -----1st component declaration:--------
  component image_generator is
    port(
      red_switch, green_switch, blue_switch : in  std_logic;
      Hsync, Vsync, Vactive, dena           : in  std_logic;
      R, G, B                               : out std_logic_vector(7 downto 0));
  end component;
  -----2nd component declaration:--------
  component control_generator is
    port(
      clk50   : in     std_logic;
      clk25   : buffer std_logic;
      clk250  : out    std_logic;
      Hsync   : buffer std_logic;
      Vsync   : out    std_logic;
      Hactive : buffer std_logic;
      Vactive : buffer std_logic;
      dena    : out    std_logic);
  end component;
  -----3rd component declaration:--------
  component tmds_encoder is
    port(
      din     : in  std_logic_vector(7 downto 0);
      control : in  std_logic_vector(1 downto 0);
      clk25   : in  std_logic;
      dena    : in  std_logic;
      dout    : out std_logic_vector(9 downto 0));
  end component;
  -----4th component declaration:--------
  component serializer is
    port(
      clk250 : in     std_logic;
      din    : in     std_logic_vector(9 downto 0);
      dout   : buffer std_logic);
  end component;
---------------------------------------
begin
  control0 <= Vsync & Hsync;
  control1 <= "00";
  control2 <= "00";
  -----Image generator:------------------
  image_gen : image_generator
    port map(
      red_switch, green_switch, blue_switch, Hsync, Vsync,
      Vactive, dena, R, G, B);
  -----Control generator:----------------
  control_gen : control_generator
    port map(
      clk50, clk25, clk250, Hsync, Vsync, open, Vactive, dena);
  -----TMDS transmitter:-----------------
  tmds0   : tmds_encoder port map(B, control0, clk25, dena, data0);
  tmds1   : tmds_encoder port map(G, control1, clk25, dena, data1);
  tmds2   : tmds_encoder port map(R, control2, clk25, dena, data2);
  serial0 : serializer port map(clk250, data0, tmds0a);
  serial1 : serializer port map(clk250, data1, tmds1a);
  serial2 : serializer port map(clk250, data2, tmds2a);
  tmds0b    <= not tmds0a;
  tmds1b    <= not tmds1a;
  tmds2b    <= not tmds2a;
  tmds_clka <= clk25;
  tmds_clkb <= not clk25;
end dvi;
---------------------------------------------------------------------
