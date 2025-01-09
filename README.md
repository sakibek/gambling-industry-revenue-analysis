# Gambling Revenue Forecasting

## Description
This project focuses on forecasting gambling industry revenue using SARIMA and NNETAR models. The analysis highlights trends, seasonality, and key insights to support strategic decision-making. NNETAR outperformed SARIMA in prediction accuracy, providing actionable insights for budgeting, resource allocation, and market expansion during peak seasons.

## Technical Details
- **Data Characteristics**:
  - Non-seasonally adjusted quarterly revenue data from January 2009 to April 2024.
  - Trend: Revenue shows exponential growth with seasonality, peaking in the first quarter each year.
  - Stationarity achieved through first-order differencing (KPSS test, ACF/PACF charts).

- **Models Used**:
  1. **SARIMA Models**:
     - Three variations optimized for trend and seasonality using AIC and Ljung-Box test.
     - Example: SARIMA(0,1,2)x(0,0,1) with quarterly seasonality.
  2. **Neural Networks (NNETAR)**:
     - Baseline, small, and large models with Fourier terms for seasonal pattern enhancement.
     - NNETAR achieved the lowest RMSE among all models.

- **Tools and Techniques**:
  - Time series decomposition for stationarity checks.
  - Ljung-Box test to validate residual independence.
  - Python libraries: `pandas`, `statsmodels`, and `forecast`.

## Results
- **Performance**:
  - NNETAR outperformed SARIMA with lower RMSE, indicating better predictive accuracy.
- **Insights**:
  - Revenue peaks in Q1 annually, suggesting optimal periods for resource allocation and marketing investments.
  - Accurate forecasting aids in mitigating economic risks and planning for market expansions.

## Use Cases
1. **Budgeting and Planning**:
   - Allocate resources for high-revenue quarters, such as marketing and staffing.
2. **Inventory and Resource Optimization**:
   - Ensure sufficient supplies and staffing during peak periods.
3. **Market Expansion**:
   - Use predictions to guide investments in new markets and online platforms.

## Files
- **Revenue_Data.csv**: Quarterly revenue dataset.
- **Forecasting_Models.ipynb**: Jupyter Notebook with SARIMA and NNETAR implementations.
- **Insights_Report.pdf**: Presentation summarizing findings and recommendations.

## Contact
For further details or collaboration, connect with me on [LinkedIn](https://www.linkedin.com/in/sakibek).
