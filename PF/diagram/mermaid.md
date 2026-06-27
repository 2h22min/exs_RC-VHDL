gantt
    title Secure Streaming Datapath - Cycle Timeline
    tickInterval 1second
    dateFormat :ss
    axisFormat %S
    
    section Byte Pipeline
    Read ROM & Enable encrypter             :b0_read, :00, 1s
    Encryption (enable=1) 1 clk/bit         :b0_encA, after b0_read, 8s
    ctrl1 rx_line low to start receiving    :done, b0_encB, after b0_read, 1s
    Capture encrypted bits with one-cycle offset :b0_encC, after b0_encB, 8s
    Wait CRC & raise rx_line to stop        :done, b0_ctrl1rxCRC, after b0_encC, 1s
    Assert tx_start to trigger transmission :done, b0_ctrl1rxSTOP, after b0_ctrl1rxCRC, 1s
    tx_data looped from encrypted ctrl1 rx_data    :b0_ctrl1txSTART, after b0_ctrl1rxSTOP, 1s
    Central UART Transmission               :b0_tx, after b0_ctrl1txSTART, 11s
    controler2 enable decrypter of rx_data  :b0_rx, after b0_tx, 1s
    Decryption (enable=1) 1 clk/bit         :b0_decA, after b0_rx, 8s
    Capture decrypted bits with one-cycle offset :b0_decB, :26, 8s
    Buffer & update running sum             :b0_sum, after b0_decB, 1s
    RAM write (enable=1) rolling avg if full window     :crit, b0_ram, after b0_sum, 1s
    Enable decrypter of next byte & repeat... :b1_rx, after b0_ram, 1s
    
    Controler1 concurrency alignment : vert, v1, :12, 1
    section Next Byte
    Read next ROM address & Enable encrypter    :b1_read, after b0_ctrl1rxSTOP, 1s
    Encryption (enable=1) 1 clk/bit             :b1_encA, after b1_read, 8s
    ctrl1 rx_line low to start receiving        :done, b1_encB, after b1_read, 1s
    Capture encrypted bits with one-cycle offset :b1_encC, after b1_encB, 8s
    Wait CRC & raise rx_line to stop            :done, b1_ctrl1rxCRC, after b1_encC, 1s
    Assert tx_start to trigger transmission     :done, b1_ctrl1rxSTOP, after b1_ctrl1rxCRC, 1s
    tx_data looped from encrypted ctrl1 rx_data :b1_ctrl1txSTART, after b1_ctrl1rxSTOP, 1s
    Central UART Transmission                   :b1_tx, after b1_ctrl1txSTART, 11s

    Controler2 loop start : vert, v2, :24, 1
    Controler2 loop end : vert, v3, :36, 1
