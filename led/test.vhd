library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;


entity test is
  port(clk  : in  std_logic;
       rst  : in  std_logic;
       led  : out std_logic;
       led2 : out std_logic;
       sw0  : in  std_logic);
end test;

architecture Behavioral of test is

  constant CLK_FREQ   : integer := 50000000;
  constant BLINK_FREQ : integer := 1;
  constant CNT_MAX    : integer := CLK_FREQ/BLINK_FREQ/2 - 1;

  signal cnt   : unsigned(24 downto 0);
  signal blink : std_logic := '1';

begin

  process(clk)
  begin

    if (clk = '1' and clk'event) then
      if cnt = CNT_MAX then
        cnt   <= (others => '0');
        blink <= not blink;
      else
        cnt <= cnt + 1;
      end if;
    end if;

  end process;

  process(sw0)
  begin

    if sw0 = '1' then
      led2 <= '1';
    else led2 <= '0';
    end if;

  end process;

  led <= blink;

end Behavioral;
