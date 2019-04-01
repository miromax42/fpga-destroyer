---created in atom
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dvi_int_test is
  port (
    clk50                                 :        std_logic;
    red_switch, green_switch, blue_switch : in     std_logic;
    tmds0a, tmds0b                        : buffer std_logic;  --TMDS0+, TMDS0-
    tmds1a, tmds1b                        : buffer std_logic;  --TMDS1+, TMDS1-
    tmds2a, tmds2b                        : buffer std_logic;  --TMDS2+, TMDS2-
    tmds_clka, tmds_clkb                  : buffer std_logic  --TMDS_clk+,TMDS_clk-
    );
end entity;

architecture arch of dvi_int_test is
  component dvi_intervention            ---pll25to250
    port (
      i_tmds0a, i_tmds0b, i_tmds1a, i_tmds1b, i_tmds2a, i_tmds2b, i_tmds_CLKa, i_tmds_CLKb : in     std_logic;
      o_tmds0a, o_tmds0b, o_tmds1a, o_tmds1b, o_tmds2a, o_tmds2b, o_tmds_CLKa, o_tmds_CLKb : buffer std_logic
      );
  end component dvi_intervention;
  component dvi_stripes                 --altera_pll (50 to 250MHz)
    port (
      clk50                                 : in     std_logic;
      red_switch, green_switch, blue_switch : in     std_logic;
      tmds0a, tmds0b                        : buffer std_logic;
      tmds1a, tmds1b                        : buffer std_logic;
      tmds2a, tmds2b                        : buffer std_logic;
      tmds_clka, tmds_clkb                  : out    std_logic
      );
  end component dvi_stripes;
  signal c_tmds0a, c_tmds0b, c_tmds1a, c_tmds1b, c_tmds2a, c_tmds2b, c_tmds_CLKa, c_tmds_CLKb : std_logic;
begin
  c1 : dvi_stripes port map(clk50, red_switch, green_switch, blue_switch, c_tmds0a, c_tmds0b, c_tmds1a, c_tmds1b, c_tmds2a, c_tmds2b, c_tmds_CLKa, c_tmds_CLKb);
  c2 : dvi_intervention port map(c_tmds0a, c_tmds0b, c_tmds1a, c_tmds1b, c_tmds2a, c_tmds2b, c_tmds_CLKa, c_tmds_CLKb,
                                 tmds0a, tmds0b, tmds1a, tmds1b, tmds2a, tmds2b, tmds_CLKa, tmds_CLKb);
end architecture;
