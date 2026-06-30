The feature importance module helps you identify the valuable features in predicting the target outcome. The **Variable Importance Plot (VIP)** highlights these features in order of their **Importance** values. This outcome is achieved by employing the Random Forest machine learning algorithm. 

In technical terms, the **Importance** value of a **Variable** is the total reduction in the **Gini impurity** brought by that **Variable** across all Decision Trees in the Random Forest.
Hence, a higher mean decrease in impurity indicates that the feature is more important.
Values presented in the module do not have a unit of measure.

**Module inputs**

- **Number of trees**: Indicates the number of Decision Trees you want to build in the Random Forest model.
A higher number can provide a more accurate outcome, but can also significantly increase computational time depending upon the sample size.
By default we use 501 decision trees.
Notice that the number is odd - it helps to avoid a decision parity.
  
- **Sample size**: Allows the user to choose the data sample size.
A larger sample size will result in longer computational time for two reasons: more data to download, and more data to train the model on.

- **Variable selection options**: Provides the user with the ability to control which variables are used in the model.
By default, we will try to compute feature importance across all variables available to us.
However, the user can either exclude certain variables from the calculation, or even provide a limited subset of variables.
