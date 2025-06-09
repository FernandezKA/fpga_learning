`timescale 1ns / 1ps

module tb_blink_debounce();

    // Параметры тестбенча
    parameter CLK_PERIOD = 20; // 20 ns = 50 MHz (соответствует реальной частоте)

    // Сигналы
    logic clk;
    logic reset_n;
    logic button;
    logic led;

    // Переопределение параметров для ускорения симуляции
    blink_debounce #(
        .CLK_FREQ(50_000_000),   // Сохраняем реальную частоту
        .DEBOUNCE_TIME(0.02)     // Уменьшаем время стабилизации до 20 µs (вместо 20 ms)
    ) dut (
        .i_clk(clk),
        .i_reset_n(reset_n),
        .i_button(button),
        .o_led(led)
    );

    // Генерация тактового сигнала
    always begin
        clk = 0;
        #(CLK_PERIOD/2);
        clk = 1;
        #(CLK_PERIOD/2);
    end

    // Основная последовательность тестирования
    initial begin
        // Инициализация
        reset_n = 0;
        button = 0;
        #100;
        
        // Снятие сброса
        reset_n = 1;
        #100;
        $display("Reset released");
        
        // Тест 1: Проверка начального состояния
        if (led !== 1'b0) $error("Test 1: LED should be 0 after reset");
        else $display("Test 1: Initial state PASSED");
        
        // Тест 2: Имитация дребезга кнопки
        $display("Test 2: Debounce simulation");
        button = 0;
        repeat(10) begin
            #(CLK_PERIOD * 1) button = $random;
        end
        button = 1; // Стабильное нажатие
        #(CLK_PERIOD * 100);
        
        // Тест 3: Проверка переключения режимов
        $display("Test 3: Mode switching");
        
        // Цикл по всем режимам
        for (int i = 0; i < 4; i++) begin
            // Генерируем "нажатие" кнопки
            button = 0;
            #(CLK_PERIOD * 10);
            button = 1;
            #(CLK_PERIOD * 100);
            
            // Проверка текущего режима
            $display("Mode %0d: div_value = %0d", 
                     dut.mode_counter, 
                     dut.current_div);
        end
        
        // Тест 4: Проверка периодов работы
        $display("Test 4: LED period measurement");
        
        // Замер периода для каждого режима
        for (int mode = 0; mode < 3; mode++) begin
            // Переключение в нужный режим
            force dut.mode_counter = mode;
            force dut.current_div = dut.DIV_VALUES[mode];
            release dut.mode_counter;
            release dut.current_div;
            
            // Ожидание стабилизации
            #(CLK_PERIOD * 10);
            
            // Измерение периода
            fork
                begin
                    time start_time, end_time;
                    @(posedge led);
                    start_time = $time;
                    @(posedge led);
                    end_time = $time;
                    $display("Mode %0d: Period = %0t ns", 
                             mode, 
                             end_time - start_time);
                end
            join_none
            
            // Ожидание завершения измерения
            #(dut.DIV_VALUES[mode] * CLK_PERIOD * 2);
        end
        
        // Завершение симуляции
        #100;
        $display("All tests completed");
        $finish;
    end

    // Мониторинг сигналов
    initial begin
        $dumpfile("waveforms.vcd");
        $dumpvars(0, tb_blink_debounce);
        $monitor("Time = %0t: button = %b, led = %b, mode = %0d",
                 $time, button, led, dut.mode_counter);
    end

endmodule