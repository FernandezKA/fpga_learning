module blink_debounce (
    input  logic i_clk,
    input  logic i_reset_n,
    input  logic i_button,
    output logic o_led
);

    // Параметры системы
    localparam CLK_FREQ = 50_000_000;          // Тактовая частота (50 МГц)
    localparam DEBOUNCE_TIME = 20;             // Время стабилизации (мс)
    localparam DEBOUNCE_CYCLES = (CLK_FREQ * DEBOUNCE_TIME) / 1000; // Такты для стабилизации
    localparam DEBOUNCE_CNT_WIDTH = $clog2(DEBOUNCE_CYCLES); // Разрядность счетчика дребезга
    
    // Параметры режимов работы
    localparam NUM_MODES = 3;                   // Количество режимов мигания
    localparam DIV_CNT_WIDTH = $clog2(CLK_FREQ); // Разрядность счетчика делителя
    localparam bit [DIV_CNT_WIDTH-1:0] DIV_VALUES[NUM_MODES] = '{
        CLK_FREQ / 1, // Режим 0: период 2 секунды (1 Гц)
        CLK_FREQ / 2, // Режим 1: период 1 секунда (2 Гц)
        CLK_FREQ / 4  // Режим 2: период 0.5 секунды (4 Гц)
    };
    
    // Внутренние сигналы
    logic [1:0] button_sync;                   // Регистр синхронизации
    logic [DEBOUNCE_CNT_WIDTH-1:0] debounce_counter;
    logic button_clean;                         // Очищенный сигнал кнопки
    logic button_prev_sync;                     // Предыдущее состояние синхронизированного сигнала
    logic button_prev_clean;                    // Предыдущее состояние очищенного сигнала (для детектора фронта)
    logic [1:0] mode_counter;                   // Счетчик режимов (0-2)
    logic [DIV_CNT_WIDTH-1:0] div_counter;
    logic [DIV_CNT_WIDTH-1:0] current_div;
    logic led_toggle;
    logic [1:0] next_mode;                      // Следующий режим работы

// ==================================================
// Синхронизация входа кнопки (защита от метастабильности)
// ==================================================
always_ff @(posedge i_clk or negedge i_reset_n) begin
    if (!i_reset_n)
        button_sync <= 2'b00;
    else
        button_sync <= {button_sync[0], i_button};
end

// ==================================================
// Модуль устранения дребезга кнопки (исправлено)
// ==================================================    
always_ff @(posedge i_clk or negedge i_reset_n) begin
    if (!i_reset_n) begin
        debounce_counter <= 0;
        button_clean     <= 0;
        button_prev_sync <= 0;
    end else begin 
        button_prev_sync <= button_sync[1];       // Запоминаем предыдущее значение
        
        // Сбрасываем счетчик при изменении входа, иначе инкрементируем
        if (button_sync[1] != button_prev_sync) begin 
            debounce_counter <= 0;
        end else if (debounce_counter < DEBOUNCE_CYCLES) begin
            debounce_counter <= debounce_counter + 1;
        end else begin
            button_clean <= button_sync[1];       // Обновляем после стабилизации
        end
    end 
end    

always_comb begin
    next_mode = (mode_counter == NUM_MODES - 1) ? 2'd0 : (mode_counter + 1);
end

// ==================================================
// Детектор фронта кнопки и переключение режимов
// ==================================================
always_ff @(posedge i_clk or negedge i_reset_n) begin
    if (!i_reset_n) begin 
        button_prev_clean <= 0;
        mode_counter      <= 0;
        current_div       <= DIV_VALUES[0];
    end else begin 
        button_prev_clean <= button_clean;        // Запоминаем предыдущее значение
        
        // Детектор фронта: 0 -> 1
        if (!button_prev_clean && button_clean) begin 
            mode_counter <= next_mode;
            current_div  <= DIV_VALUES[next_mode];
        end
    end
end  

// ==================================================
// Счётчик делителя частоты и управление светодиодом
// ==================================================
always_ff @(posedge i_clk or negedge i_reset_n) begin
    if (!i_reset_n) begin 
        div_counter <= 0;
        led_toggle  <= 0;
    end else begin 
        if (div_counter >= current_div - 1) begin 
            div_counter <= 0;
            led_toggle  <= ~led_toggle;
        end else begin
            div_counter <= div_counter + 1;
        end
    end
end 

assign o_led = led_toggle;

endmodule