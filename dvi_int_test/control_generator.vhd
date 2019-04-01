library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_detector is
  generic(
    Ha : integer := 96;                 --Hpulse
    Hb : integer := 144;                --Hpulse+HBP
    Hc : integer := 784;                --Hpulse+HBP+Hactive
    Hd : integer := 800;                --Hpulse+HBP+Hactive+HFP
    Va : integer := 2;                  --Vpulse
    Vb : integer := 35;                 --Vpulse+VBP
    Vc : integer := 515;                --Vpulse+VBP+Vactive
    Vd : integer := 525;                --Vpulse+VBP+Vactive+VFP
    Hs : integer := 200;                --start H
    Vs : integer := 200;                --start V
    He : integer := 300;                --length H
    Ve : integer := 300);               --length V
  port (
    clk25        : in     std_logic;
    din          : in     std_logic_vector(9 downto 0);
    Hsync        : buffer std_logic;    --Horizontal sync
    Vsync        : out    std_logic;    --Vertical sync
    Hactive      : buffer std_logic;    --Active portion of Hsync
    Hactive_mini : buffer std_logic;
    Vactive      : buffer std_logic;    --Active portion of Vsync
    Vactive_mini : buffer std_logic;    --Active portion of Vsync
    dena_main    : buffer std_logic;
    dena_mini    : buffer std_logic;
    err          : buffer std_logic     --no Hsync
    );
end entity;

architecture arch of control_detector is
begin
  cntl : process(clk25)
  begin
    if din = "1101010100" then          --v0 h0
      Vsync <= '0';
      Hsync <= '0';
    elsif din = "0010101011" then       --01
      Vsync <= '0';
      Hsync <= '1';
    elsif din = "0101010100" then       --10
      Vsync <= '1';
      Hsync <= '0';
    elsif din = "1010101011" then       --OTHERS(11)
      Vsync <= '1';
      Hsync <= '1';
    else
      Vsync <= '1';
      Hsync <= '1';
    end if;
  end process;

  process(clk25)
    variable Hcount : integer range 0 to Hd;
  begin
    if (clk25'event and clk25 = '1') then
      if Hsync = '1' then
        Hcount := Hcount + 1;
        if (Hcount = Hb-Ha) then
          Hactive <= '1';
        elsif (Hcount = Hc-Ha+Hs) then
          Hactive_mini <= '1';
        elsif (Hcount = Hc-Ha+He) then
          Hactive_mini <= '0';
        elsif (Hcount = Hc-Ha) then
          Hactive <= '0';
        elsif (Hcount = Hd-Ha) then

          Hcount := 0;
        end if;
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

      elsif (Vcount = Vb) then
        Vactive <= '1';
      elsif (Vcount = Vb+Vs) then
        Vactive_mini <= '1';
      elsif (Vcount = Vb+Ve) then
        Vactive_mini <= '0';
      elsif (Vcount = Vc) then
        Vactive <= '0';
      elsif (Vcount = Vd) then

        Vcount := 0;
      end if;
    end if;
  end process;
  -----Display-enable generation:--------
  dena_main <= Hactive and Vactive;
  dena_mini <= Hactive_mini and Vactive_mini;
  process(clk25)
    variable count : integer := 0;
  begin
    if dena_main = '0' then
      count := count+1;
      if count = 9999999 then
        err <= '1';
      elsif count = 10000000 then
        err   <= '0';
        count := 0;
      end if;
    end if;
  end process;
end architecture;
-----Control generator:--------------------------------------

--IF (control = "00") THEN
--  dout <= "1101010100";
--ELSIF (control = "01") THEN
--  dout <= "0010101011";
--ELSIF (control = "10") THEN
--  dout <= "0101010100";
--ELSE
--  dout <= "1010101011";
--END IF;
--control0  <= Vsync & Hsync;
--control1  <= "00";
--control2  <= "00";
