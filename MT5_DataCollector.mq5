//+------------------------------------------------------------------+
//|                                           MT5_DataCollector.mq5 |
//|                        Copyright 2024, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property script_show_inputs

//--- Input parameters
input int      MA_Period_1 = 20;           // First Moving Average Period
input int      MA_Period_2 = 50;           // Second Moving Average Period
input ENUM_MA_METHOD MA_Method = MODE_SMA; // Moving Average Method
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // Applied Price
input int      Data_Collection_Points = 1000; // Number of data points to collect
input string   File_Name = "MA_Data.csv";  // Output file name
input bool     Collect_On_Cross = true;    // Collect data on MA crossovers
input bool     Collect_On_Trend = true;    // Collect data on trend changes
input double   Min_Price_Distance = 0.001; // Minimum price distance for collection

//--- Global variables
int ma_handle_1, ma_handle_2;
double ma_buffer_1[], ma_buffer_2[];
datetime time_buffer[];
double price_buffer[];
int data_count = 0;
string csv_header = "Time,Open,High,Low,Close,Volume,MA1,MA2,MA_Diff,MA_Cross,MA_Trend";

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    // Initialize moving average handles
    ma_handle_1 = iMA(_Symbol, _Period, MA_Period_1, 0, MA_Method, MA_Price);
    ma_handle_2 = iMA(_Symbol, _Period, MA_Period_2, 0, MA_Method, MA_Price);
    
    if(ma_handle_1 == INVALID_HANDLE || ma_handle_2 == INVALID_HANDLE)
    {
        Print("Error: Failed to create MA handles");
        return;
    }
    
    // Set array as series
    ArraySetAsSeries(ma_buffer_1, true);
    ArraySetAsSeries(ma_buffer_2, true);
    ArraySetAsSeries(time_buffer, true);
    ArraySetAsSeries(price_buffer, true);
    
    // Initialize arrays
    ArrayResize(ma_buffer_1, Data_Collection_Points);
    ArrayResize(ma_buffer_2, Data_Collection_Points);
    ArrayResize(time_buffer, Data_Collection_Points);
    ArrayResize(price_buffer, Data_Collection_Points);
    
    Print("Starting data collection...");
    Print("Symbol: ", _Symbol, " Period: ", _Period);
    Print("MA1 Period: ", MA_Period_1, " MA2 Period: ", MA_Period_2);
    
    // Collect data
    CollectData();
    
    // Save data to file
    SaveDataToFile();
    
    Print("Data collection completed. Total points collected: ", data_count);
}

//+------------------------------------------------------------------+
//| Collect data based on moving average conditions                 |
//+------------------------------------------------------------------+
void CollectData()
{
    int total_bars = Bars(_Symbol, _Period);
    if(total_bars < MA_Period_2 + 10)
    {
        Print("Error: Not enough bars for analysis");
        return;
    }
    
    // Copy MA data
    if(CopyBuffer(ma_handle_1, 0, 0, Data_Collection_Points, ma_buffer_1) <= 0 ||
       CopyBuffer(ma_handle_2, 0, 0, Data_Collection_Points, ma_buffer_2) <= 0)
    {
        Print("Error: Failed to copy MA buffers");
        return;
    }
    
    // Copy time data
    if(CopyTime(_Symbol, _Period, 0, Data_Collection_Points, time_buffer) <= 0)
    {
        Print("Error: Failed to copy time buffer");
        return;
    }
    
    // Copy close prices
    if(CopyClose(_Symbol, _Period, 0, Data_Collection_Points, price_buffer) <= 0)
    {
        Print("Error: Failed to copy price buffer");
        return;
    }
    
    // Analyze data for collection conditions
    for(int i = MA_Period_2; i < Data_Collection_Points && data_count < Data_Collection_Points; i++)
    {
        if(ShouldCollectData(i))
        {
            // Store the data point
            StoreDataPoint(i);
        }
    }
}

//+------------------------------------------------------------------+
//| Determine if data should be collected at this point            |
//+------------------------------------------------------------------+
bool ShouldCollectData(int index)
{
    if(index < 1) return false;
    
    double ma1_current = ma_buffer_1[index];
    double ma1_previous = ma_buffer_1[index + 1];
    double ma2_current = ma_buffer_2[index];
    double ma2_previous = ma_buffer_2[index + 1];
    
    // Check for MA crossover
    if(Collect_On_Cross)
    {
        // Bullish crossover: MA1 crosses above MA2
        if(ma1_previous <= ma2_previous && ma1_current > ma2_current)
        {
            return true;
        }
        // Bearish crossover: MA1 crosses below MA2
        if(ma1_previous >= ma2_previous && ma1_current < ma2_current)
        {
            return true;
        }
    }
    
    // Check for trend changes
    if(Collect_On_Trend)
    {
        // Check if price distance from MA is significant
        double price_distance = MathAbs(price_buffer[index] - ma1_current);
        if(price_distance >= Min_Price_Distance)
        {
            // Check for trend continuation or reversal
            bool current_bullish = ma1_current > ma2_current;
            bool previous_bullish = ma1_previous > ma2_previous;
            
            if(current_bullish != previous_bullish)
            {
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Store data point for analysis                                   |
//+------------------------------------------------------------------+
void StoreDataPoint(int index)
{
    if(data_count >= Data_Collection_Points) return;
    
    // Get OHLCV data for this bar
    MqlRates rates[];
    if(CopyRates(_Symbol, _Period, index, 1, rates) <= 0)
    {
        Print("Error: Failed to copy rates for index ", index);
        return;
    }
    
    // Calculate additional metrics
    double ma_diff = ma_buffer_1[index] - ma_buffer_2[index];
    string ma_cross = GetMACrossType(index);
    string ma_trend = GetMATrend(index);
    
    // Store in arrays (we'll write to file later)
    time_buffer[data_count] = time_buffer[index];
    price_buffer[data_count] = price_buffer[index];
    
    data_count++;
    
    // Print progress
    if(data_count % 100 == 0)
    {
        Print("Collected ", data_count, " data points...");
    }
}

//+------------------------------------------------------------------+
//| Get MA cross type                                               |
//+------------------------------------------------------------------+
string GetMACrossType(int index)
{
    if(index < 1) return "NONE";
    
    double ma1_current = ma_buffer_1[index];
    double ma1_previous = ma_buffer_1[index + 1];
    double ma2_current = ma_buffer_2[index];
    double ma2_previous = ma_buffer_2[index + 1];
    
    if(ma1_previous <= ma2_previous && ma1_current > ma2_current)
        return "BULLISH";
    else if(ma1_previous >= ma2_previous && ma1_current < ma2_current)
        return "BEARISH";
    else
        return "NONE";
}

//+------------------------------------------------------------------+
//| Get MA trend                                                    |
//+------------------------------------------------------------------+
string GetMATrend(int index)
{
    double ma1_current = ma_buffer_1[index];
    double ma2_current = ma_buffer_2[index];
    
    if(ma1_current > ma2_current)
        return "BULLISH";
    else if(ma1_current < ma2_current)
        return "BEARISH";
    else
        return "NEUTRAL";
}

//+------------------------------------------------------------------+
//| Save collected data to CSV file                                |
//+------------------------------------------------------------------+
void SaveDataToFile()
{
    int file_handle = FileOpen(File_Name, FILE_WRITE | FILE_CSV);
    if(file_handle == INVALID_HANDLE)
    {
        Print("Error: Failed to create file ", File_Name);
        return;
    }
    
    // Write header
    FileWrite(file_handle, csv_header);
    
    // Write data
    for(int i = 0; i < data_count; i++)
    {
        // Get OHLCV data for this timestamp
        MqlRates rates[];
        datetime target_time = time_buffer[i];
        
        // Find the bar with this timestamp
        int bar_index = iBarShift(_Symbol, _Period, target_time);
        if(bar_index >= 0)
        {
            if(CopyRates(_Symbol, _Period, bar_index, 1, rates) > 0)
            {
                double ma1_val = ma_buffer_1[i];
                double ma2_val = ma_buffer_2[i];
                double ma_diff = ma1_val - ma2_val;
                string ma_cross = GetMACrossType(i);
                string ma_trend = GetMATrend(i);
                
                // Write CSV line
                FileWrite(file_handle, 
                    TimeToString(target_time, TIME_DATE | TIME_MINUTES),
                    DoubleToString(rates[0].open, _Digits),
                    DoubleToString(rates[0].high, _Digits),
                    DoubleToString(rates[0].low, _Digits),
                    DoubleToString(rates[0].close, _Digits),
                    IntegerToString(rates[0].tick_volume),
                    DoubleToString(ma1_val, _Digits),
                    DoubleToString(ma2_val, _Digits),
                    DoubleToString(ma_diff, _Digits),
                    ma_cross,
                    ma_trend
                );
            }
        }
    }
    
    FileClose(file_handle);
    Print("Data saved to file: ", File_Name);
}

//+------------------------------------------------------------------+
//| Script deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release MA handles
    if(ma_handle_1 != INVALID_HANDLE)
        IndicatorRelease(ma_handle_1);
    if(ma_handle_2 != INVALID_HANDLE)
        IndicatorRelease(ma_handle_2);
    
    Print("MT5 Data Collector script deinitialized");
}