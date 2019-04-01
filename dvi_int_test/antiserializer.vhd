-- antiserializerGUN----------------------------
-------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
entity antiserializer is
  port (
    clk250 : in     std_logic;
    err    : buffer std_logic;
    din    : in     std_logic;
    dout   : out    std_logic_vector(9 downto 0)
    );
end entity;
architecture rtl of antiserializer is

  signal internal : std_logic_vector(9 downto 0);

begin
  serial : process(clk250)
    variable count : integer range 0 to 9 := 0;
    variable c_err : integer range 0 to 9 := 0;

  begin
    if rising_edge(clk250) then
      count := count + 1;
      if err = '1' then
        c_err := c_err+1;
        if c_err = 9 then
          c_err := 0;
          if count = 9 then
            count := 0;
          else
            count := count+1;
          end if;
        end if;
      end if;
      if (count = 9) then
        internal(count) <= din;
      elsif (count = 10) then
        count := 0;
      end if;
      dout <= internal;
    end if;
  end process;
end architecture;
