TX FSM:                          RX FSM:
┌──────────┐                    ┌──────────┐
│  IDLE    │                    │  IDLE    │
└────┬─────┘                    └────┬─────┘
     │ en_tx=1                       │ start_bit detectado
     ▼                               ▼
┌──────────────┐                ┌──────────────┐
│ TRANSMITTING │                │ RECEIVING    │
└────┬─────────┘                └────┬─────────┘
     │ 11 bits enviados              │ 11 bits recebidos
     ▼                               ▼
┌──────────┐                    ┌──────────┐
│  IDLE    │                    │  IDLE    │
└──────────┘                    └──────────┘
