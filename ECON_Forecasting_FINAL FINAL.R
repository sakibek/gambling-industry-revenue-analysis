library(fpp3)
library(urca)
library(readr)

temp = readr::read_csv("gambling.csv")
gambling = temp%>%mutate(DATE = yearquarter(ymd(DATE)))%>%as_tsibble(index = DATE)

#STEP 1
gamblingHOLD = gambling%>%filter_index("2009 Q1" ~ "2022 Q4")

colnames(gambling)[colnames(gambling) == "DATA"] <- "data"
colnames(gamblingHOLD)[colnames(gamblingHOLD) == "DATA"] <- "data"

colnames(gambling)[colnames(gambling) == "REV7132TAXABL144QNSA"] <- "revenue"
colnames(gamblingHOLD)[colnames(gamblingHOLD) == "REV7132TAXABL144QNSA"] <- "revenue"

lambda = gamblingHOLD%>%features(revenue,guerrero)%>%
  pull(lambda_guerrero)
print(lambda)

# the value of lambda indicates that we do not need a box-cox transformation

# Check for differencing requirements
gamblingHOLD %>% features(revenue, unitroot_ndiffs)
#d=1

# Check for seasonal differencing requirements
gamblingHOLD %>% features(revenue, unitroot_nsdiffs)
#D=0

# Perform KPSS test for stationarity
gamblingHOLD %>% features(revenue, unitroot_kpss)


# Apply first-order differencing to address trend non-stationarity
gamblingHOLD <- gamblingHOLD %>%
  mutate(revenue_diff = difference(revenue)) %>%
  filter(!is.na(revenue_diff)) # Remove NA values caused by differencing


# Re-test stationarity using KPSS on the differenced series
gamblingHOLD %>% features(revenue_diff, unitroot_kpss)

#Revenue which was not Differenced
gamblingHOLD %>%
  gg_tsdisplay(revenue, plot_type = "partial", lag_max = 16)



# Visualize ACF and PACF for the differenced series
gamblingHOLD %>%
  gg_tsdisplay(revenue_diff, plot_type = "partial", lag_max = 16)


gamblingHOLD%>%autoplot(revenue)
gamblingHOLD%>%autoplot(log(revenue)) #Testing for log transformation, we find that we do not need it
gamblingHOLD%>%gg_season(revenue)


models <- gamblingHOLD %>%
  model(
    SARIMA1 = ARIMA(revenue_diff ~ 0 + pdq(0, 1, 1) + PDQ(0, 0, 1, period = 4)), 
    SARIMA2 = ARIMA(revenue_diff ~ 0 + pdq(0, 1, 2) + PDQ(0, 0, 1, period = 4)), 
    SARIMA3 = ARIMA(revenue_diff ~ 0 + pdq(1, 1, 1) + PDQ(1, 0, 1, period = 4)), 
    
  )

# Compare AIC and SIC (BIC) values for model selection
model_comparison <- glance(models) %>%
  select(.model, AIC, BIC)

# Print the comparison
print(model_comparison)


# Display model summaries for each SARIMA model
sarima_summary1 <- models %>%
  select(SARIMA1) %>%
  report()

print("SARIMA1 Summary:")
print(sarima_summary1)


# Display model summaries for each SARIMA model
sarima_summary2 <- models %>%
  select(SARIMA2) %>%
  report()

print("SARIMA2 Summary:")
print(sarima_summary2)

# Display model summaries for each SARIMA model
sarima_summary3 <- models %>%
  select(SARIMA3) %>%
  report()

print("SARIMA3 Summary:")
print(sarima_summary3)

#RESIDUALS

models %>%
  select(SARIMA1) %>%
  gg_tsresiduals() +
  labs(title = "Residual Diagnostics for SARIMA1")

# Residual diagnostics for SARIMA2
models %>%
  select(SARIMA2) %>%
  gg_tsresiduals() +
  labs(title = "Residual Diagnostics for SARIMA2")

# Residual diagnostics for SARIMA2
models %>%
  select(SARIMA3) %>%
  gg_tsresiduals() +
  labs(title = "Residual Diagnostics for SARIMA3")


# Ljung-Box Test for Residuals

ljung_box_results <- models %>%
  augment() %>%
  features(.resid, ljung_box, lag = 24, dof = 2)

# Print Ljung-Box test results
print("Ljung-Box Test Results:")
print(ljung_box_results)


gambling <- gambling %>%
  mutate(revenue_diff = difference(revenue))

# Generate forecasts for 6 quarters ahead
forecast_results <- models %>%
  forecast(h = 6)  

# Plot forecasts with actual observations, filtering for the correct range
forecast_plot <- forecast_results %>%
  autoplot(gambling %>% filter_index("2009 Q1" ~ "2024 Q2")) +  # Filter range with yearquarter format
  labs(
    title = "Forecast Comparison: SARIMA Models",
    x = "Time",
    y = "Revenue"
  ) +
  theme_minimal()

# Print the forecast plot
print(forecast_plot)


# Baseline Neural Network Model
fitAUTO <- gamblingHOLD %>%
  model(
    NNETAR(
      revenue_diff ~ AR(p = 1,P=1),  
      n_networks = 100         
    )
  )

# Print a detailed report of the fitted model
report(fitAUTO)


fitAUTO%>%forecast(h=6,times=100,bootstrap=TRUE)%>%
  autoplot(gambling%>%filter_index("2009 Q1" ~ "2024 Q2"))


# Small Neural Network Model
smallNET <- gamblingHOLD %>%
  model(
    NNETAR(
      revenue_diff ~ AR(p = 1,P=1)+fourier(period=4,K=2),  
      n_networks = 100         
    )
  )

# Print a detailed report of the fitted model
report(smallNET)

smallNET%>%forecast(h=6,times=100,bootstrap=TRUE)%>%
  autoplot(gambling%>%filter_index("2009 Q1" ~ "2024 Q2"))


# Small Neural Network Model
bigNET <- gamblingHOLD %>%
  model(
    NNETAR(
      revenue_diff ~ AR(p = 1,P=1)+fourier(period=12,K=2), 
      n_networks = 100          
    )
  )

# Print a detailed report of the fitted model
report(bigNET)

bigNET%>%forecast(h=6,times=100,bootstrap=TRUE)%>%
  autoplot(gambling%>%filter_index("2009 Q1" ~ "2024 Q2"))


# Compare AIC, BIC, and other metrics
model_comparison <- bind_rows(
  glance(fitAUTO) %>% mutate(Model = "NNETAR1"),
  glance(smallNET) %>% mutate(Model = "NNETAR2"),
  glance(bigNET) %>% mutate(Model = "NNETAR3")
)

# Print the comparison table
print(model_comparison)


# Generate forecasts for the validation period
forecasts <- forecast(fitAUTO, h = 6) 

# Calculate accuracy metrics
accuracy_metrics <- accuracy(forecasts, gambling)  

# Print accuracy metrics
print(accuracy_metrics)



# Generate forecasts for the validation period
forecasts2 <- forecast(smallNET, h = 6)  

# Calculate accuracy metrics
accuracy_metrics2 <- accuracy(forecasts2, gambling)  

# Print accuracy metrics
print(accuracy_metrics2)


# Generate forecasts for the validation period
forecasts3 <- forecast(bigNET, h = 6)  

# Calculate accuracy metrics
accuracy_metrics3 <- accuracy(forecasts3, gambling)  

# Print accuracy metrics
print(accuracy_metrics3)


# Generate forecasts for SARIMA3
sarima2_forecast <- models %>%
  select(SARIMA2) %>%
  forecast(h = 6)  

# Calculate accuracy for SARIMA3 using the validation data
sarima2_accuracy <- accuracy(sarima2_forecast, gambling %>% filter_index("2023 Q1" ~ "2024 Q2"))

# Print the accuracy metrics
print("Accuracy Metrics for SARIMA2:")
print(sarima2_accuracy)

#Forecast into Future

# Train SARIMA model on the entire dataset
models_full <- gambling %>%
  model(
    SARIMA2 = ARIMA(revenue_diff ~ pdq(0, 1, 2) + PDQ(0, 1, 1, period = 4))
  )

modelFINAL <- gambling %>%
  model(
    NNETAR(
      revenue_diff ~ AR(p = 1,P=1),  
      n_networks = 100          
    )
  )

# Generate forecasts for the next 8 quarters
future_forecast <- modelFINAL %>%
  #select(SARIMA2) %>%
  forecast(h = 8)

# Plot forecasts for future periods
future_forecast %>%
  autoplot(gambling) +  # Only show forecast and confidence intervals
  labs(
    title = "8-Quarter Future Forecast (NNET fitAUTO)",
    x = "Time",
    y = "Revenue"
  ) +
  theme_minimal()



