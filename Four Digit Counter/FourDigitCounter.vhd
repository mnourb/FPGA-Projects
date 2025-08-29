library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FourDigitCounter is
    Generic (
        CLK_FREQ : natural := 50_000_000; -- Input clock frequency in Hz (default 50 MHz)
        MUX_FREQ : natural := 1000;        -- Digit multiplexing frequency in Hz (1ms period)
        COUNT_FREQ : natural := 1         -- Counter increment frequency in Hz (1s period)
    );
    Port (
        clk : in  STD_LOGIC;
        rst : in  STD_LOGIC;
        seg_data : out STD_LOGIC_VECTOR (7 downto 0); -- 7-segment display data
        digit_select : out STD_LOGIC_VECTOR (3 downto 0) -- Digit selection signals
    );
end FourDigitCounter;

architecture Behavioral of FourDigitCounter is
    type sevenSegmentArray is array (natural range 0 to 9) of STD_LOGIC_VECTOR(7 downto 0);
    constant sevenSegmentCodes : sevenSegmentArray := (
        x"3f", -- 0
        x"06", -- 1
        x"5b", -- 2
        x"4f", -- 3
        x"66", -- 4
        x"6d", -- 5
        x"7d", -- 6
        x"07", -- 7
        x"7f", -- 8
        x"6f"  -- 9
    );
    signal clk_divider : natural range 0 to CLK_FREQ := 0; -- Clock divider for counter
    signal mux_divider : natural range 0 to CLK_FREQ := 0; -- Clock divider for multiplexing
    signal mux_tick : STD_LOGIC := '0'; -- 1ms tick for digit multiplexing
    signal count_tick : STD_LOGIC := '0'; -- 1s tick for counter increment
    signal digit_idx : natural range 0 to 3 := 0; -- Current digit index
    signal counter_value : natural range 0 to 9999 := 0; -- 4-digit counter
    signal digit0, digit1, digit2, digit3 : natural range 0 to 9; -- Individual digits
    signal seg_output : STD_LOGIC_VECTOR (7 downto 0); -- Output to 7-segment display

    -- Calculate counter thresholds based on generics
    constant MUX_THRESHOLD : natural := CLK_FREQ / (2 * MUX_FREQ); -- e.g., 50M / (2 * 1000) = 25000
    constant COUNT_THRESHOLD : natural := CLK_FREQ / (2 * COUNT_FREQ); -- e.g., 50M / (2 * 1) = 25M
begin
    -- Clock divider for multiplexing (1ms) and counter increment (1s)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_divider <= 0;
                mux_divider <= 0;
                mux_tick <= '0';
                count_tick <= '0';
            else
                clk_divider <= clk_divider + 1;
                mux_divider <= mux_divider + 1;
                if mux_divider >= MUX_THRESHOLD then
                    mux_divider <= 0;
                    mux_tick <= not mux_tick;
                end if;
                if clk_divider >= COUNT_THRESHOLD then
                    clk_divider <= 0;
                    count_tick <= not count_tick;
                end if;
            end if;
        end if;
    end process;

    -- Counter increment every second
    process(count_tick)
    begin
        if rising_edge(count_tick) then
            if rst = '1' then
                counter_value <= 0;
            elsif counter_value = 9999 then
                counter_value <= 0;
            else
                counter_value <= counter_value + 1;
            end if;
        end if;
    end process;

    -- Digit multiplexing every 1ms
    process(mux_tick)
    begin
        if rising_edge(mux_tick) then
            if rst = '1' then
                digit_idx <= 0;
                digit0 <= 0;
                digit1 <= 0;
                digit2 <= 0;
                digit3 <= 0;
                seg_output <= sevenSegmentCodes(0);
                digit_select <= "0001";
            else
                -- Extract digits
                digit0 <= counter_value mod 10;
                digit1 <= (counter_value / 10) mod 10;
                digit2 <= (counter_value / 100) mod 10;
                digit3 <= (counter_value / 1000) mod 10;

                -- Multiplex digits
                case digit_idx is
                    when 0 =>
                        digit_select <= "1000";
                        seg_output <= sevenSegmentCodes(digit3);
                    when 1 =>
                        digit_select <= "0100";
                        seg_output <= sevenSegmentCodes(digit2);
                    when 2 =>
                        digit_select <= "0010";
                        seg_output <= sevenSegmentCodes(digit1);
                    when 3 =>
                        digit_select <= "0001";
                        seg_output <= sevenSegmentCodes(digit0);
                    when others =>
                        digit_select <= "0001";
                        seg_output <= sevenSegmentCodes(0);
                end case;
                digit_idx <= (digit_idx + 1) mod 4;
            end if;
        end if;
    end process;

    seg_data <= seg_output;
end Behavioral;