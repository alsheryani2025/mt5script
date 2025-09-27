# MetaTrader 5 Data Collection Scripts

This repository contains MetaTrader 5 scripts designed for collecting market data based on moving average conditions and trading strategies.

## 📁 Files Included

- `MT5_DataCollector.mq5` - Basic data collection script
- `MT5_AdvancedDataCollector.mq5` - Advanced data collection with multiple indicators
- `MT5_DataCollector_Config.txt` - Configuration guide and usage instructions

## 🚀 Quick Start

### 1. Installation
1. Copy the `.mq5` files to your MetaTrader 5 `Scripts` folder
2. Open MetaEditor and compile the scripts
3. Run the script on your desired chart

### 2. Basic Usage
```mql5
// Run the basic script with default settings
// This will collect data when MA crossovers occur
```

### 3. Advanced Usage
```mql5
// Configure the advanced script for your strategy
// Set MA periods, collection conditions, and filters
```

## 📊 Features

### Basic Script Features:
- ✅ Two moving average crossover detection
- ✅ Trend change identification
- ✅ OHLCV data collection
- ✅ CSV file output
- ✅ Customizable parameters

### Advanced Script Features:
- ✅ Three moving average system (fast, slow, trend)
- ✅ Multiple collection conditions
- ✅ Time and volume filtering
- ✅ RSI and ATR calculations
- ✅ Price action analysis
- ✅ Enhanced data output

## 🎯 Strategy Examples

### Golden Cross Strategy
```mql5
MA_Period_1 = 50
MA_Period_2 = 200
Collect_On_Cross = true
Collect_On_Trend = true
```

### Scalping Strategy
```mql5
MA_Fast_Period = 5
MA_Slow_Period = 10
MA_Trend_Period = 20
Min_Price_Move = 0.0001
Use_Time_Filter = true
```

### Trend Following Strategy
```mql5
MA_Fast_Period = 20
MA_Slow_Period = 50
MA_Trend_Period = 100
Collect_Trend_Changes = true
Collect_Price_Action = true
```

## 📈 Output Data Format

The scripts generate CSV files with the following columns:

| Column | Description |
|--------|-------------|
| Time | Bar timestamp |
| Open, High, Low, Close | OHLC prices |
| Volume | Tick volume |
| MA_Fast, MA_Slow, MA_Trend | Moving average values |
| MA_Diff | Difference between fast and slow MA |
| Cross_Type | Crossover type (BULLISH/BEARISH/NONE) |
| Trend_Type | Current trend (BULL/BEAR/NEUTRAL) |
| Price_Action | Price action classification |
| RSI | Relative Strength Index |
| ATR | Average True Range |

## ⚙️ Configuration

### Input Parameters

#### Basic Script:
- `MA_Period_1`: First moving average period
- `MA_Period_2`: Second moving average period
- `MA_Method`: MA calculation method (SMA, EMA, etc.)
- `Data_Collection_Points`: Maximum data points to collect
- `File_Name`: Output CSV filename
- `Collect_On_Cross`: Enable crossover collection
- `Collect_On_Trend`: Enable trend change collection

#### Advanced Script:
- `MA_Fast_Period`: Fast MA period
- `MA_Slow_Period`: Slow MA period
- `MA_Trend_Period`: Trend MA period
- `Max_Data_Points`: Maximum data points
- `Collect_Crossovers`: Enable crossover collection
- `Collect_Trend_Changes`: Enable trend change collection
- `Collect_Price_Action`: Enable price action collection
- `Min_Volume`: Minimum volume filter
- `Use_Time_Filter`: Enable time-based filtering

## 🔧 Customization

### Adding New Conditions
You can modify the `ShouldCollectData()` or `ShouldCollectAtBar()` functions to add your own collection conditions:

```mql5
bool ShouldCollectData(int index)
{
    // Add your custom conditions here
    if(YourCustomCondition(index))
        return true;
    
    // Existing conditions...
    return false;
}
```

### Adding New Indicators
To add new indicators, create handles and copy buffers:

```mql5
int rsi_handle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
double rsi_buffer[];
CopyBuffer(rsi_handle, 0, 0, Max_Data_Points, rsi_buffer);
```

## 📝 Usage Tips

1. **Data Requirements**: Ensure you have sufficient historical data for your MA periods
2. **File Size**: Monitor output file size for large datasets
3. **Timeframes**: Choose appropriate timeframes for your strategy
4. **Parameters**: Adjust parameters based on your trading strategy
5. **Testing**: Test with small datasets first

## 🐛 Troubleshooting

### Common Issues:
- **"Not enough bars"**: Increase historical data or reduce MA periods
- **"Failed to create file"**: Check file permissions and disk space
- **"Invalid handle"**: Ensure indicators are properly initialized

### Solutions:
- Use longer timeframes for more historical data
- Check file path and permissions
- Verify indicator parameters are correct

## 📞 Support

For issues or questions:
1. Check the configuration guide
2. Verify your MT5 setup
3. Test with default parameters first
4. Review the script logs for error messages

## 🔄 Updates

- Version 1.0: Basic data collection script
- Version 2.0: Advanced script with multiple indicators and filters

## 📄 License

This project is provided as-is for educational and research purposes. Use at your own risk.