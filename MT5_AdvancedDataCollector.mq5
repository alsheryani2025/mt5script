//+------------------------------------------------------------------+
//|                                    MT5_AdvancedDataCollector.mq5 |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "2.00"
#property script_show_inputs

//--- Input parameters
input group "=== Moving Average Settings ==="
input int      MA_Fast_Period = 10;        // Fast Moving Average Period
input int      MA_Slow_Period = 20;        // Slow Moving Average Period
input int      MA_Trend_Period = 50;       // Trend Moving Average Period
input ENUM_MA_METHOD MA_Method = MODE_EMA; // Moving Average Method
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // Applied Price

input group "=== Data Collection Settings ==="
input int      Max_Data_Points = 5000;     // Maximum data points to collect
input string   Output_File = "MA_Strategy_Data.csv"; // Output file name
input bool     Collect_Crossovers = true;  // Collect MA crossover data
input bool     Collect_Trend_Changes = true; // Collect trend change data
input bool     Collect_Price_Action = true; // Collect price action data
input double   Min_Price_Move = 0.0001;    // Minimum price movement
input int      Lookback_Bars = 100;        // Bars to look back for analysis

input group "=== Filter Settings ==="
input double   Min_Volume = 100;           // Minimum volume filter
input bool     Use_Time_Filter = false;    // Use time-based filtering
input int      Start_Hour = 9;             // Start hour (24h format)
input int      End_Hour = 17;              // End hour (24h format)

//--- Global variables
int ma_fast_handle, ma_slow_handle, ma_trend_handle;
double ma_fast[], ma_slow[], ma_trend[];
datetime time_data[];
double open_data[], high_data[], low_data[], close_data[];
long volume_data[];
int data_count = 0;
string csv_header = "Time,Open,High,Low,Close,Volume,MA_Fast,MA_Slow,MA_Trend,MA_Diff,Cross_Type,Trend_Type,Price_Action,RSI,ATR";

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== MT5 Advanced Data Collector Started ===");
    
    // Initialize indicators
    if(!InitializeIndicators())
    {
        Print("Error: Failed to initialize indicators");
        return;
    }
    
    // Collect data
    if(!CollectMarketData())
    {
        Print("Error: Failed to collect market data");
        return;
    }
    
    // Save data to file
    SaveDataToCSV();
    
    Print("=== Data Collection Completed ===");
    Print("Total data points collected: ", data_count);
    Print("Output file: ", Output_File);
}

//+------------------------------------------------------------------+
//| Initialize all indicators                                        |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
    // Create MA handles
    ma_fast_handle = iMA(_Symbol, _Period, MA_Fast_Period, 0, MA_Method, MA_Price);
    ma_slow_handle = iMA(_Symbol, _Period, MA_Slow_Period, 0, MA_Method, MA_Price);
    ma_trend_handle = iMA(_Symbol, _Period, MA_Trend_Period, 0, MA_Method, MA_Price);
    
    if(ma_fast_handle == INVALID_HANDLE || ma_slow_handle == INVALID_HANDLE || ma_trend_handle == INVALID_HANDLE)
    {
        Print("Error: Failed to create MA handles");
        return false;
    }
    
    // Set arrays as series
    ArraySetAsSeries(ma_fast, true);
    ArraySetAsSeries(ma_slow, true);
    ArraySetAsSeries(ma_trend, true);
    ArraySetAsSeries(time_data, true);
    ArraySetAsSeries(open_data, true);
    ArraySetAsSeries(high_data, true);
    ArraySetAsSeries(low_data, true);
    ArraySetAsSeries(close_data, true);
    ArraySetAsSeries(volume_data, true);
    
    // Resize arrays
    ArrayResize(ma_fast, Max_Data_Points);
    ArrayResize(ma_slow, Max_Data_Points);
    ArrayResize(ma_trend, Max_Data_Points);
    ArrayResize(time_data, Max_Data_Points);
    ArrayResize(open_data, Max_Data_Points);
    ArrayResize(high_data, Max_Data_Points);
    ArrayResize(low_data, Max_Data_Points);
    ArrayResize(close_data, Max_Data_Points);
    ArrayResize(volume_data, Max_Data_Points);
    
    Print("Indicators initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Collect market data based on conditions                         |
//+------------------------------------------------------------------+
bool CollectMarketData()
{
    int total_bars = Bars(_Symbol, _Period);
    if(total_bars < MA_Trend_Period + Lookback_Bars)
    {
        Print("Error: Not enough historical data");
        return false;
    }
    
    // Copy indicator data
    if(CopyBuffer(ma_fast_handle, 0, 0, Max_Data_Points, ma_fast) <= 0 ||
       CopyBuffer(ma_slow_handle, 0, 0, Max_Data_Points, ma_slow) <= 0 ||
       CopyBuffer(ma_trend_handle, 0, 0, Max_Data_Points, ma_trend) <= 0)
    {
        Print("Error: Failed to copy MA buffers");
        return false;
    }
    
    // Copy market data
    if(CopyTime(_Symbol, _Period, 0, Max_Data_Points, time_data) <= 0 ||
       CopyOpen(_Symbol, _Period, 0, Max_Data_Points, open_data) <= 0 ||
       CopyHigh(_Symbol, _Period, 0, Max_Data_Points, high_data) <= 0 ||
       CopyLow(_Symbol, _Period, 0, Max_Data_Points, low_data) <= 0 ||
       CopyClose(_Symbol, _Period, 0, Max_Data_Points, close_data) <= 0 ||
       CopyTickVolume(_Symbol, _Period, 0, Max_Data_Points, volume_data) <= 0)
    {
        Print("Error: Failed to copy market data");
        return false;
    }
    
    // Analyze and collect data
    for(int i = MA_Trend_Period; i < Max_Data_Points && data_count < Max_Data_Points; i++)
    {
        if(ShouldCollectAtBar(i))
        {
            StoreDataPoint(i);
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Determine if data should be collected at this bar               |
//+------------------------------------------------------------------+
bool ShouldCollectAtBar(int index)
{
    if(index < 2) return false;
    
    // Time filter
    if(Use_Time_Filter)
    {
        MqlDateTime dt;
        TimeToStruct(time_data[index], dt);
        if(dt.hour < Start_Hour || dt.hour > End_Hour)
            return false;
    }
    
    // Volume filter
    if(volume_data[index] < Min_Volume)
        return false;
    
    // Check for crossover conditions
    if(Collect_Crossovers && CheckForCrossover(index))
        return true;
    
    // Check for trend changes
    if(Collect_Trend_Changes && CheckForTrendChange(index))
        return true;
    
    // Check for price action
    if(Collect_Price_Action && CheckForPriceAction(index))
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for moving average crossovers                             |
//+------------------------------------------------------------------+
bool CheckForCrossover(int index)
{
    double fast_curr = ma_fast[index];
    double fast_prev = ma_fast[index + 1];
    double slow_curr = ma_slow[index];
    double slow_prev = ma_slow[index + 1];
    
    // Bullish crossover
    if(fast_prev <= slow_prev && fast_curr > slow_curr)
        return true;
    
    // Bearish crossover
    if(fast_prev >= slow_prev && fast_curr < slow_curr)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for trend changes                                         |
//+------------------------------------------------------------------+
bool CheckForTrendChange(int index)
{
    double fast_curr = ma_fast[index];
    double slow_curr = ma_slow[index];
    double trend_curr = ma_trend[index];
    
    double fast_prev = ma_fast[index + 1];
    double slow_prev = ma_slow[index + 1];
    double trend_prev = ma_trend[index + 1];
    
    // Check if trend direction changed
    bool current_bullish = (fast_curr > slow_curr) && (slow_curr > trend_curr);
    bool previous_bullish = (fast_prev > slow_prev) && (slow_prev > trend_prev);
    
    return (current_bullish != previous_bullish);
}

//+------------------------------------------------------------------+
//| Check for significant price action                               |
//+------------------------------------------------------------------+
bool CheckForPriceAction(int index)
{
    double price_change = MathAbs(close_data[index] - close_data[index + 1]);
    double price_range = high_data[index] - low_data[index];
    
    // Check for significant price movement
    if(price_change >= Min_Price_Move)
        return true;
    
    // Check for high volatility
    if(price_range >= (close_data[index] * 0.01)) // 1% range
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Store data point                                                 |
//+------------------------------------------------------------------+
void StoreDataPoint(int index)
{
    if(data_count >= Max_Data_Points) return;
    
    data_count++;
    
    // Print progress
    if(data_count % 500 == 0)
    {
        Print("Collected ", data_count, " data points...");
    }
}

//+------------------------------------------------------------------+
//| Get crossover type                                               |
//+------------------------------------------------------------------+
string GetCrossoverType(int index)
{
    if(index < 1) return "NONE";
    
    double fast_curr = ma_fast[index];
    double fast_prev = ma_fast[index + 1];
    double slow_curr = ma_slow[index];
    double slow_prev = ma_slow[index + 1];
    
    if(fast_prev <= slow_prev && fast_curr > slow_curr)
        return "BULLISH";
    else if(fast_prev >= slow_prev && fast_curr < slow_curr)
        return "BEARISH";
    else
        return "NONE";
}

//+------------------------------------------------------------------+
//| Get trend type                                                   |
//+------------------------------------------------------------------+
string GetTrendType(int index)
{
    double fast = ma_fast[index];
    double slow = ma_slow[index];
    double trend = ma_trend[index];
    
    if(fast > slow && slow > trend)
        return "STRONG_BULL";
    else if(fast > slow)
        return "BULL";
    else if(fast < slow && slow < trend)
        return "STRONG_BEAR";
    else if(fast < slow)
        return "BEAR";
    else
        return "NEUTRAL";
}

//+------------------------------------------------------------------+
//| Get price action type                                            |
//+------------------------------------------------------------------+
string GetPriceActionType(int index)
{
    if(index < 1) return "NONE";
    
    double open = open_data[index];
    double close = close_data[index];
    double high = high_data[index];
    double low = low_data[index];
    
    double body_size = MathAbs(close - open);
    double total_range = high - low;
    
    if(body_size > (total_range * 0.7))
    {
        if(close > open)
            return "STRONG_BULL";
        else
            return "STRONG_BEAR";
    }
    else if(body_size < (total_range * 0.3))
    {
        return "DOJI";
    }
    else
    {
        if(close > open)
            return "BULL";
        else
            return "BEAR";
    }
}

//+------------------------------------------------------------------+
//| Calculate RSI for the bar                                        |
//+------------------------------------------------------------------+
double CalculateRSI(int index)
{
    int rsi_handle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
    if(rsi_handle == INVALID_HANDLE) return 0;
    
    double rsi_buffer[];
    ArraySetAsSeries(rsi_buffer, true);
    
    if(CopyBuffer(rsi_handle, 0, index, 1, rsi_buffer) > 0)
    {
        IndicatorRelease(rsi_handle);
        return rsi_buffer[0];
    }
    
    IndicatorRelease(rsi_handle);
    return 0;
}

//+------------------------------------------------------------------+
//| Calculate ATR for the bar                                        |
//+------------------------------------------------------------------+
double CalculateATR(int index)
{
    int atr_handle = iATR(_Symbol, _Period, 14);
    if(atr_handle == INVALID_HANDLE) return 0;
    
    double atr_buffer[];
    ArraySetAsSeries(atr_buffer, true);
    
    if(CopyBuffer(atr_handle, 0, index, 1, atr_buffer) > 0)
    {
        IndicatorRelease(atr_handle);
        return atr_buffer[0];
    }
    
    IndicatorRelease(atr_handle);
    return 0;
}

//+------------------------------------------------------------------+
//| Save data to CSV file                                            |
//+------------------------------------------------------------------+
void SaveDataToCSV()
{
    int file_handle = FileOpen(Output_File, FILE_WRITE | FILE_CSV);
    if(file_handle == INVALID_HANDLE)
    {
        Print("Error: Failed to create file ", Output_File);
        return;
    }
    
    // Write header
    FileWrite(file_handle, csv_header);
    
    // Write data
    for(int i = 0; i < data_count; i++)
    {
        int bar_index = i + MA_Trend_Period; // Adjust for the starting index
        
        if(bar_index < Max_Data_Points)
        {
            double ma_diff = ma_fast[bar_index] - ma_slow[bar_index];
            string cross_type = GetCrossoverType(bar_index);
            string trend_type = GetTrendType(bar_index);
            string price_action = GetPriceActionType(bar_index);
            double rsi = CalculateRSI(bar_index);
            double atr = CalculateATR(bar_index);
            
            FileWrite(file_handle,
                TimeToString(time_data[bar_index], TIME_DATE | TIME_MINUTES),
                DoubleToString(open_data[bar_index], _Digits),
                DoubleToString(high_data[bar_index], _Digits),
                DoubleToString(low_data[bar_index], _Digits),
                DoubleToString(close_data[bar_index], _Digits),
                IntegerToString(volume_data[bar_index]),
                DoubleToString(ma_fast[bar_index], _Digits),
                DoubleToString(ma_slow[bar_index], _Digits),
                DoubleToString(ma_trend[bar_index], _Digits),
                DoubleToString(ma_diff, _Digits),
                cross_type,
                trend_type,
                price_action,
                DoubleToString(rsi, 2),
                DoubleToString(atr, _Digits)
            );
        }
    }
    
    FileClose(file_handle);
    Print("Data saved to: ", Output_File);
}

//+------------------------------------------------------------------+
//| Script deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release handles
    if(ma_fast_handle != INVALID_HANDLE)
        IndicatorRelease(ma_fast_handle);
    if(ma_slow_handle != INVALID_HANDLE)
        IndicatorRelease(ma_slow_handle);
    if(ma_trend_handle != INVALID_HANDLE)
        IndicatorRelease(ma_trend_handle);
    
    Print("Advanced Data Collector script deinitialized");
}