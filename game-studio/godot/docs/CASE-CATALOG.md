# Case catalog (T-035a)

Fictional data only. Source of truth for code: `data/cases.json`. Placeholders such as `{region}` are filled by the generator (T-033/T-034). Cards: `data/handbook.json`. Coaching: `data/coaching.json`.

Total cases: 33.

| id | title | skill | method | dataset | trap | diff | day |
|---|---|---|---|---|---|---|---|
| case_duplicate_export | The double export | data_cleaning | data-quality-audit | sales_export | duplicates | 1 | 1 |
| case_missing_as_zero | The silent zeros | data_cleaning | data-quality-audit | sales_export | missing_as_zero | 1 | 2 |
| case_mixed_currency | Dollars and dong in one column | data_cleaning | data-quality-audit | sales_export | mixed_units_currency | 2 | 4 |
| case_date_timezone | Midnight in two time zones | data_cleaning | data-quality-audit | web_funnel | date_timezone | 3 | 7 |
| case_category_typos | Hanoi, Ha Noi and hanoi | data_cleaning | data-quality-audit | sales_export | category_typos | 1 | 3 |
| case_entry_error_vs_spike | One extra zero | data_cleaning | programmatic-eda | market_prices | outlier_entry_error | 2 | 5 |
| case_seasonality | December is not a trend | statistics | time-series-analysis | sales_export | seasonality_vs_trend | 3 | 9 |
| case_simpson | Winner by group, loser overall | causality | segmentation-analysis | ab_test_log | simpsons_paradox | 4 | 14 |
| case_small_sample | Three customers is not a trend | statistics | programmatic-eda | support_tickets | small_sample_noise | 2 | 11 |
| case_correlation_causation | Ads and sales move together | causality | root-cause-investigation | sales_export | correlation_vs_causation | 3 | 16 |
| case_base_rate | The fraud alarm that cries wolf | statistics | programmatic-eda | loan_book | base_rate | 4 | 20 |
| case_survivorship | Only the survivors answered | causality | cohort-analysis | loan_book | survivorship_bias | 4 | 18 |
| case_cherry_picking | The perfect date range | causality | analysis-planning | market_prices | cherry_picking | 3 | 22 |
| case_misleading_axis | The chart that shouts | charts | visualization-builder | sales_export | misleading_axis | 2 | 12 |
| case_double_counting | Customers in two lists | data_cleaning | segmentation-analysis | sales_export | double_counting | 2 | 8 |
| case_late_data | The half-finished Friday | data_cleaning | time-series-analysis | web_funnel | late_arriving_data | 2 | 6 |
| case_ab_significance | Is a 7-point lift real? | statistics | ab-test-analysis | ab_test_log | ab_significance | 3 | 13 |
| case_ab_peeking | Stop the test now, it's winning | statistics | ab-test-analysis | ab_test_log | ab_peeking | 4 | 24 |
| case_ab_sample_size | Too few users to tell | statistics | ab-test-analysis | ab_test_log | ab_sample_size | 4 | 26 |
| case_funnel_dropoff | Where do customers leave? | communication | funnel-analysis | web_funnel | funnel_dropoff | 2 | 10 |
| case_cohort_retention | New users are not loyal users | communication | cohort-analysis | web_funnel | cohort_retention | 3 | 17 |
| case_segmentation | The average customer does not exist | communication | segmentation-analysis | sales_export | segmentation | 3 | 19 |
| case_root_cause | Why did revenue fall? | communication | root-cause-investigation | sales_export | root_cause_drilldown | 3 | 15 |
| case_regression_to_mean | The fix that fixed nothing | statistics | programmatic-eda | sales_export | regression_to_mean | 4 | 28 |
| case_join_mismatch | The customers who vanished | data_cleaning | data-quality-audit | loan_book | join_mismatch | 3 | 21 |
| case_test_accounts | Staff signed up too | data_cleaning | data-quality-audit | ab_test_log | test_accounts | 2 | 23 |
| case_subtotal_rows | The rows named Total | data_cleaning | data-quality-audit | sales_export | double_counting_subtotals | 2 | 25 |
| case_negative_refunds | Refunds are not errors | data_cleaning | data-quality-audit | sales_export | refunds_vs_cancellations | 2 | 27 |
| case_truncated_export | The file that stopped in September | data_cleaning | data-quality-audit | sales_export | truncated_export | 3 | 29 |
| case_competitor_scrape | Prices from a messy scrape | data_cleaning | programmatic-eda | competitor_scrape | mixed_units_currency | 3 | 30 |
| case_data_rescue | The full rescue | data_cleaning | data-quality-audit | sales_export | multiple_defects | 5 | 31 |
| case_dual_axis | Two axes, one story | charts | visualization-builder | market_prices | misleading_axis | 4 | 32 |
| case_histogram_skew | The average that describes nobody | charts | programmatic-eda | support_tickets | mean_vs_median | 3 | 33 |

## case_duplicate_export: The double export

- Skill: data_cleaning; method: data-quality-audit; dataset: sales_export; difficulty 1; unlocks day 1
- Boss question: Did unit sales in {region} rise, fall or stay flat compared with the previous week? (forecast: up/down/flat)
- Trap (duplicates): The export was run twice, so some rows appear two times and inflate the total.
- Dirt: duplicates
- Reference steps:
  1. Count rows and compare with distinct order IDs
  2. Remove duplicates using order_id plus date as the key
  3. Check the row count dropped by the number of copies
  4. Group by day and compare with the previous week
- Correct findings:
  - After removing {n_dupes} duplicate rows, units in {region} changed {pct_change} versus the previous 7 days.
  - The raw total overstated sales by {n_dupes_units} units because of the double export.
- Wrong paths:
  - Sum the raw column: Copies are counted twice so the week looks stronger than it was.
  - Delete every row that looks similar: Two genuine orders with the same product and size are not duplicates; only the full key matters.
- Handbook: hb_duplicates, hb_audit_first, hb_double_counting

## case_missing_as_zero: The silent zeros

- Skill: data_cleaning; method: data-quality-audit; dataset: sales_export; difficulty 1; unlocks day 2
- Boss question: Are daily sales in {region} falling, recovering or flat this week? (forecast: up/down/flat)
- Trap (missing_as_zero): A store whose till was offline exported 0 units instead of a blank, dragging the average down.
- Dirt: zero_as_null
- Reference steps:
  1. Sort units ascending and list the zeros
  2. Check whether the zeros match store outage days or other sources
  3. Treat confirmed outage zeros as missing
  4. Compute the daily average over the days with data
- Correct findings:
  - Daily average units were {avg_clean}, not {avg_raw}; {n_zero_days} zero days were outages, not real sales.
  - Sales in {region} are {direction} once outage days are excluded.
- Wrong paths:
  - Average the column as is: The fake zeros pull the mean down and invent a decline.
  - Fill zeros with the overall mean: That invents sales on days nothing was recorded and hides the gap.
- Handbook: hb_zero_vs_null, hb_missing_values, hb_assumptions_log

## case_mixed_currency: Dollars and dong in one column

- Skill: data_cleaning; method: data-quality-audit; dataset: sales_export; difficulty 2; unlocks day 4
- Boss question: Is average revenue per order in {region} rising, falling or flat? (forecast: up/down/flat)
- Trap (mixed_units_currency): Revenue is recorded in two currencies and in thousands in some rows, so rows are not comparable.
- Dirt: mixed_currency, mixed_units
- Reference steps:
  1. Group by the currency column to see all values
  2. Convert amounts to one currency using the stated fixed rate
  3. Convert 'k' values to plain units
  4. Recompute the average per order
- Correct findings:
  - After converting to one currency, average revenue per order was {avg_clean} per order, {pct_change} versus last week.
  - {n_rows_converted} rows were in the second currency or in thousands.
- Wrong paths:
  - Average the amount column: Small numbers in dollars and large numbers in local money are mixed, so the average means nothing.
  - Convert only the currency, not the thousands: Rows marked k are still 1000 times too small.
- Handbook: hb_units_currency, hb_percent_points, hb_audit_first

## case_date_timezone: Midnight in two time zones

- Skill: data_cleaning; method: data-quality-audit; dataset: web_funnel; difficulty 3; unlocks day 7
- Boss question: Did sign-ups jump on {date} or was it a data artefact? (forecast: up/flat)
- Trap (date_timezone): Dates arrive in mixed formats and one source uses UTC while the other uses local time, moving late-evening events to the next day.
- Dirt: mixed_dates, timezone_shift
- Reference steps:
  1. Inspect date formats and the source column
  2. Parse each source with the right format
  3. Convert both sources to one time zone
  4. Re-aggregate by day and compare
- Correct findings:
  - After aligning time zones, sign-ups on {date} were {n_clean}, not {n_raw}; the apparent jump was a day boundary shift.
  - Dates in {n_formats} formats were parsed before grouping.
- Wrong paths:
  - Group by the raw date text: Sorting text puts 10 Mar before 2 Mar and splits days.
  - Assume all rows use the same time zone: Evening events slip into the next day and create a fake spike.
- Handbook: hb_dates_timezones, hb_late_data, hb_audit_first

## case_category_typos: Hanoi, Ha Noi and hanoi

- Skill: data_cleaning; method: data-quality-audit; dataset: sales_export; difficulty 1; unlocks day 3
- Boss question: Which region sold the most units this week?
- Trap (category_typos): The same region is spelled several ways, so a group-by splits it and hides the real leader.
- Dirt: category_typos
- Reference steps:
  1. Group by region and read the list of names
  2. Standardise case, spaces and spelling variants
  3. Re-group and sort
  4. Chart as a sorted bar with units
- Correct findings:
  - {region_top} was the top region with {units_top} units after merging spelling variants.
  - {n_variants} spelling variants of {region_top} were merged.
- Wrong paths:
  - Pick the largest group in the raw list: A region split across three spellings can rank below a smaller, cleanly spelled one.
  - Merge regions that merely sound alike: Only merge names that really are the same place.
- Handbook: hb_text_standardize, hb_choose_chart, hb_sort_label

## case_entry_error_vs_spike: One extra zero

- Skill: data_cleaning; method: programmatic-eda; dataset: market_prices; difficulty 2; unlocks day 5
- Boss question: Will {commodity} prices rise, fall or stay flat this week? (forecast: up/down/flat)
- Trap (outlier_entry_error): One price is ten times its neighbours (an extra zero), while a separate, smaller jump is a genuine market move.
- Dirt: entry_outliers
- Reference steps:
  1. Plot the series as a line
  2. Flag outliers with the IQR rule
  3. Check the flagged points against neighbours and a second source
  4. Fix the typo and keep the persistent real move
  5. Read the trend from the cleaned series
- Correct findings:
  - The {date_bad} value was an entry error (about 10x the neighbours) and was corrected.
  - The rise from {level_before} to {level_after} persisted for {n_days} days and is real.
- Wrong paths:
  - Delete every flagged point: The persistent rise is real information and is removed with the typo.
  - Keep all points: A single wrong value makes the average and the chart useless.
- Handbook: hb_entry_error_vs_spike, hb_outliers_iqr, hb_line_time

## case_seasonality: December is not a trend

- Skill: statistics; method: time-series-analysis; dataset: sales_export; difficulty 3; unlocks day 9
- Boss question: Is demand in {region} really recovering, or is it just the usual seasonal pattern? (forecast: up/down/flat)
- Trap (seasonality_vs_trend): A repeating seasonal peak looks like growth when compared with the preceding off-season period.
- Dirt: none (analysis trap)
- Reference steps:
  1. Chart at least two years on the same axis
  2. Compare with the same period last year
  3. Estimate the typical seasonal swing
  4. Report the year-on-year change as the trend
- Correct findings:
  - Sales are {pct_mom} versus last month but {pct_yoy} versus the same month last year.
  - About {pct_season} of the rise matches the normal seasonal swing.
- Wrong paths:
  - Compare to last month: The previous month is seasonally low, so any month looks like growth.
  - Fit a straight line to the whole series: The line ignores the repeating pattern and misleads about direction.
- Handbook: hb_seasonality, hb_line_time, hb_moving_average

## case_simpson: Winner by group, loser overall

- Skill: causality; method: segmentation-analysis; dataset: ab_test_log; difficulty 4; unlocks day 14
- Boss question: Which checkout version converts better, A or B?
- Trap (simpsons_paradox): Variant B converts better inside both device groups but looks worse overall because it received mostly mobile traffic.
- Dirt: none (analysis trap)
- Reference steps:
  1. Compute conversion by variant
  2. Split by device and recompute
  3. Compare variants inside each device
  4. Report the like-for-like result and the traffic mix difference
- Correct findings:
  - B converts better than A on desktop ({a_desktop} vs {b_desktop}) and on mobile ({a_mobile} vs {b_mobile}).
  - The overall gap is reversed because the device mix differs between variants.
- Wrong paths:
  - Declare the overall winner: The overall rate reflects a different mix of devices, not the quality of the page.
  - Always trust the subgroups: Check why the mix differs; if assignment was not random, neither view is final.
- Handbook: hb_simpson, hb_confounder, hb_segmentation

## case_small_sample: Three customers is not a trend

- Skill: statistics; method: programmatic-eda; dataset: support_tickets; difficulty 2; unlocks day 11
- Boss question: Is satisfaction in {category} better or worse than last month? (forecast: up/down/flat)
- Trap (small_sample_noise): A category with very few responses swings wildly and looks like a big change.
- Dirt: none (analysis trap)
- Reference steps:
  1. Count responses per category
  2. Mark groups below a minimum count
  3. Compare the large groups only, or pool several months
  4. Report counts with each rate
- Correct findings:
  - {category} had only {n} responses, so a change of {pct_change} is within normal noise.
  - Categories with at least {n_min} responses were stable.
- Wrong paths:
  - Rank categories by satisfaction rate: Tiny groups sit at the top and bottom of any ranking by chance.
  - Ignore the small group entirely: Say it is uncertain instead of hiding it.
- Handbook: hb_noise_sample, hb_confidence_interval, hb_report_findings

## case_correlation_causation: Ads and sales move together

- Skill: causality; method: root-cause-investigation; dataset: sales_export; difficulty 3; unlocks day 16
- Boss question: Did the ad campaign cause the sales rise in {region}? (forecast: up/down/flat)
- Trap (correlation_vs_causation): Ad spend and sales both rise because of a third factor (a holiday season), so the link is not causal.
- Dirt: none (analysis trap)
- Reference steps:
  1. Chart spend and sales over time
  2. Check for a common driver such as season or price promotion
  3. Compare treated and untreated regions or periods
  4. Word the finding as an association unless a test exists
- Correct findings:
  - Ad spend and sales are associated (r = {r}), but a holiday explains much of the rise.
  - Regions without the campaign rose by {pct_control}, so the campaign effect is at most {pct_effect}.
- Wrong paths:
  - Say the campaign caused the rise: Without a comparison group, a coincident holiday explains the same pattern.
  - Say there is no relationship: There is a link; it just cannot be called causal from this data.
- Handbook: hb_corr_vs_cause, hb_confounder, hb_scatter

## case_base_rate: The fraud alarm that cries wolf

- Skill: statistics; method: programmatic-eda; dataset: loan_book; difficulty 4; unlocks day 20
- Boss question: The risk model flags an account. Is it likely a real default?
- Trap (base_rate): The model is accurate, but defaults are rare, so most flags are false alarms.
- Dirt: none (analysis trap)
- Reference steps:
  1. State the base rate of default
  2. Build a table of flagged and not flagged by real outcome
  3. Compute the share of flags that are real
  4. Report precision, not just model accuracy
- Correct findings:
  - Only {precision} of flagged accounts actually default because defaults are rare ({base_rate}).
  - Out of {n_flags} flags, {n_true} were real defaults.
- Wrong paths:
  - Treat a flag as a 90% chance of default: Accuracy figures ignore how rare the event is.
  - Ignore the model completely: It still raises the odds; use it as a screen, not a verdict.
- Handbook: hb_base_rate, hb_report_findings, hb_confidence_calibration

## case_survivorship: Only the survivors answered

- Skill: causality; method: cohort-analysis; dataset: loan_book; difficulty 4; unlocks day 18
- Boss question: How risky is our loan book, based on the default rate? (forecast: up/down/flat)
- Trap (survivorship_bias): Closed and defaulted accounts were removed from the export, so the book looks safer than it is.
- Dirt: survivorship
- Reference steps:
  1. Check the status column for closed or charged-off values
  2. Ask what was removed and request the full history
  3. Build cohorts by origination month and track defaults over time
  4. Report the default rate with and without closed accounts
- Correct findings:
  - The export only contained {n_open} open accounts; {n_closed} closed accounts were missing.
  - Including closed accounts, the default rate is {rate_full}, not {rate_open}.
- Wrong paths:
  - Compute the default rate from the file: Defaulted accounts are the ones that were removed.
  - Assume the missing accounts all defaulted: Many closed accounts were simply repaid; get the real records.
- Handbook: hb_survivorship, hb_cohort, hb_missing_values

## case_cherry_picking: The perfect date range

- Skill: causality; method: analysis-planning; dataset: market_prices; difficulty 3; unlocks day 22
- Boss question: A colleague says {series} has risen {pct_cherry} this month. Is that fair? (forecast: up/down/flat)
- Trap (cherry_picking): The quoted rise starts at a temporary low and ends at a temporary high; over the full period the series is flat.
- Dirt: none (analysis trap)
- Reference steps:
  1. Ask for the start and end dates behind the claim
  2. Chart the full period
  3. Compare several windows
  4. State the change over a window chosen before looking
- Correct findings:
  - The quoted rise holds only for {window_cherry}; over the full period the change was {pct_full}.
  - Different windows gave results from {low} to {high}.
- Wrong paths:
  - Accept the quoted figure: It is real but selected to look good.
  - Call the colleague dishonest: Say the window is arbitrary and show the full picture.
- Handbook: hb_cherry_pick, hb_seasonality, hb_assumptions_log

## case_misleading_axis: The chart that shouts

- Skill: charts; method: visualization-builder; dataset: sales_export; difficulty 2; unlocks day 12
- Boss question: Make a chart of sales for the board. Does {region} outperform the others?
- Trap (misleading_axis): A bar chart whose axis starts at a high value makes a 3% difference look enormous.
- Dirt: none (analysis trap)
- Reference steps:
  1. Aggregate units by region
  2. Build a bar chart with the Y-axis starting at zero
  3. Sort the bars and add units and a clear title
  4. State the real size of the difference
- Correct findings:
  - {region} sold {pct_gap} more than the next region, a modest difference.
  - With a zero-based axis the bars look similar, which matches the data.
- Wrong paths:
  - Truncate the axis to show differences clearly: Truncation makes small gaps look huge and misleads the board.
  - Use a pie chart instead: Pies make small differences harder to see, not more honest.
- Handbook: hb_bar_axis, hb_sort_label, hb_dual_axis, hb_pie_caution

## case_double_counting: Customers in two lists

- Skill: data_cleaning; method: segmentation-analysis; dataset: sales_export; difficulty 2; unlocks day 8
- Boss question: How many unique customers bought in {region} this month?
- Trap (double_counting): Customers who bought through both web and app appear in both channel lists, so adding the lists overstates unique customers.
- Dirt: duplicates
- Reference steps:
  1. Count customers in each channel
  2. Find customers present in both
  3. Count unique customer IDs across channels
  4. Check parts versus total
- Correct findings:
  - There were {n_unique} unique customers, not {n_sum}; {n_overlap} used both channels.
  - Channel totals add to more than the true total.
- Wrong paths:
  - Add the web and app counts: Customers who used both are counted twice.
  - Use only the larger channel: That ignores customers who bought only through the other one.
- Handbook: hb_double_counting, hb_duplicates, hb_subtotal_rows

## case_late_data: The half-finished Friday

- Skill: data_cleaning; method: time-series-analysis; dataset: web_funnel; difficulty 2; unlocks day 6
- Boss question: Did sign-ups fall sharply on the last day, and should we panic? (forecast: down/flat)
- Trap (late_arriving_data): The last day in the export is incomplete, so it looks like a crash.
- Dirt: late_arriving
- Reference steps:
  1. Check export time versus end of day
  2. Compare the last day's volume to a normal day at the same hour
  3. Exclude or flag the partial day
  4. Report the trend on complete days
- Correct findings:
  - The final day was a partial day (exported at {export_time}); the trend on complete days was {direction}.
  - Excluding the partial day, average sign-ups were {avg_complete}.
- Wrong paths:
  - Report a collapse on the last day: The records had not arrived yet.
  - Delete the last day without saying so: Note that data was excluded and why.
- Handbook: hb_late_data, hb_dates_timezones, hb_line_time

## case_ab_significance: Is a 7-point lift real?

- Skill: statistics; method: ab-test-analysis; dataset: ab_test_log; difficulty 3; unlocks day 13
- Boss question: Variant B looks better. Should we roll it out? (forecast: up/flat)
- Trap (ab_significance): A visible difference may still be random; significance depends on the sample size and the p-value.
- Dirt: test_accounts
- Reference steps:
  1. Remove test accounts
  2. Check the groups are similar in size
  3. Compute conversion per variant
  4. Run the significance test and read the p-value with the effect size
  5. Recommend roll out only if the difference is meaningful and significant
- Correct findings:
  - B converts {rate_b} versus {rate_a} for A (p = {p}); the result is {sig_word}.
  - The effect is {diff_points} points; the interval ranges from {ci_low} to {ci_high}.
- Wrong paths:
  - Pick the higher rate: Without a significance check the gap may be luck.
  - Say p = 0.04 means a 96% chance B is better: A p-value is not the probability that the hypothesis is true.
- Handbook: hb_ab_test, hb_pvalue, hb_confidence_interval

## case_ab_peeking: Stop the test now, it's winning

- Skill: statistics; method: ab-test-analysis; dataset: ab_test_log; difficulty 4; unlocks day 24
- Boss question: The test hit p < 0.05 on day 3 of a 14-day plan. Can we stop and ship? (forecast: up/flat)
- Trap (ab_peeking): Checking a test repeatedly and stopping at the first significant result inflates false positives.
- Dirt: none (analysis trap)
- Reference steps:
  1. Review the planned sample size and duration
  2. Compute how many looks were taken
  3. Treat early significance as provisional
  4. Wait for the planned sample, or use a sequential method
- Correct findings:
  - The test planned {n_plan} users per variant but had {n_now}; the early result is provisional.
  - With {n_looks} looks, the chance of at least one false positive is far above 5%.
- Wrong paths:
  - Stop and ship because p < 0.05: Repeated looks make false winners common.
  - Throw away the test: The data is fine; it is the stopping rule that is not.
- Handbook: hb_peeking, hb_pvalue, hb_sample_size

## case_ab_sample_size: Too few users to tell

- Skill: statistics; method: ab-test-analysis; dataset: ab_test_log; difficulty 4; unlocks day 26
- Boss question: The new button shows +1 point, but the test only had a few hundred users. What do we know? (forecast: flat/up)
- Trap (ab_sample_size): The test is too small to detect a small effect, so 'no significant difference' does not mean 'no difference'.
- Dirt: none (analysis trap)
- Reference steps:
  1. Compute the required users per variant for the target lift
  2. Compare with the actual sample
  3. Report the result as inconclusive
  4. Recommend running longer or accepting a bigger minimum lift
- Correct findings:
  - The test had {n_actual} users per variant but needed about {n_needed} to detect {lift}.
  - The result is inconclusive, not negative.
- Wrong paths:
  - Conclude the button has no effect: Absence of evidence is not evidence of absence in a small test.
  - Conclude the button works: The interval includes zero.
- Handbook: hb_sample_size, hb_confidence_interval, hb_pvalue

## case_funnel_dropoff: Where do customers leave?

- Skill: communication; method: funnel-analysis; dataset: web_funnel; difficulty 2; unlocks day 10
- Boss question: Which step of the sign-up flow should we fix first?
- Trap (funnel_dropoff): Raw counts hide which step loses the largest share; the biggest percentage drop is the best place to look.
- Dirt: none (analysis trap)
- Reference steps:
  1. Order steps and count users per step
  2. Compute step-to-step conversion
  3. Find the largest proportional drop
  4. Check that the last day is complete
  5. Segment the weak step by device or source
- Correct findings:
  - The biggest drop is from {step_a} to {step_b} ({conv_step}).
  - Overall conversion from visit to purchase is {conv_total}.
- Wrong paths:
  - Fix the step with the largest absolute drop: The first step always loses the most users in raw numbers.
  - Include the partial last day: That makes late steps look worse than they are.
- Handbook: hb_funnel, hb_late_data, hb_segmentation

## case_cohort_retention: New users are not loyal users

- Skill: communication; method: cohort-analysis; dataset: web_funnel; difficulty 3; unlocks day 17
- Boss question: Is customer retention improving? (forecast: up/down/flat)
- Trap (cohort_retention): Overall active users grow because of new sign-ups while every new cohort retains worse than the last.
- Dirt: none (analysis trap)
- Reference steps:
  1. Define a cohort by sign-up month
  2. Compute weeks since sign-up for each event
  3. Build a retention table by cohort
  4. Compare cohorts at the same age
- Correct findings:
  - Week-4 retention fell from {ret_old} to {ret_new} across cohorts, although total active users grew.
  - Growth is driven by new sign-ups, not stickiness.
- Wrong paths:
  - Look at total active users: New sign-ups hide churn.
  - Compare cohorts of different ages: Older cohorts have had more time to fall; compare at the same age.
- Handbook: hb_cohort, hb_survivorship, hb_funnel

## case_segmentation: The average customer does not exist

- Skill: communication; method: segmentation-analysis; dataset: sales_export; difficulty 3; unlocks day 19
- Boss question: Our average basket is flat. Is anything changing? (forecast: up/down/flat)
- Trap (segmentation): A flat average hides two segments moving in opposite directions.
- Dirt: none (analysis trap)
- Reference steps:
  1. Compute the average basket overall
  2. Segment by customer type or channel
  3. Compare each segment over time
  4. Report segment sizes and changes
- Correct findings:
  - The overall average is flat, but {segment_a} rose {pct_a} while {segment_b} fell {pct_b}.
  - Segment sizes were {n_a} and {n_b}.
- Wrong paths:
  - Report that nothing changed: The movement cancels out in the average.
  - Create dozens of segments: Small segments are noisy; keep a few meaningful ones.
- Handbook: hb_segmentation, hb_noise_sample, hb_histogram

## case_root_cause: Why did revenue fall?

- Skill: communication; method: root-cause-investigation; dataset: sales_export; difficulty 3; unlocks day 15
- Boss question: Revenue fell {pct_drop} this week. Why? (forecast: down)
- Trap (root_cause_drilldown): A total decline is caused by one narrow part (one region and product); the first plausible reason is not the full explanation.
- Dirt: none (analysis trap)
- Reference steps:
  1. Confirm the drop is real (not a data issue)
  2. Split by region, then product, then channel
  3. Find the part explaining most of the change
  4. Check that the finding accounts for the whole drop
- Correct findings:
  - {region} {product} explains {share_explained} of the decline.
  - Other regions were within normal variation.
- Wrong paths:
  - Blame the economy: It is a story, not a finding.
  - Stop after the first split: A region-level drop may still hide a single product.
- Handbook: hb_root_cause, hb_segmentation, hb_audit_first

## case_regression_to_mean: The fix that fixed nothing

- Skill: statistics; method: programmatic-eda; dataset: sales_export; difficulty 4; unlocks day 28
- Boss question: We ran a promotion in the 5 weakest shops and sales rose. Did it work? (forecast: up/down/flat)
- Trap (regression_to_mean): Shops chosen for being the worst tend to improve next period even with no action.
- Dirt: none (analysis trap)
- Reference steps:
  1. Check how the shops were chosen
  2. Look at several earlier periods
  3. Compare with similar untreated shops
  4. Estimate the effect beyond the natural rebound
- Correct findings:
  - The 5 treated shops rose {pct_treated}, but similar untreated weak shops rose {pct_control}.
  - Most of the rise matches a natural rebound.
- Wrong paths:
  - Credit the promotion: Extreme results are partly luck and tend to move toward the average.
  - Say the promotion hurt: It did not; the effect is simply unproven.
- Handbook: hb_regression_mean, hb_noise_sample, hb_corr_vs_cause

## case_join_mismatch: The customers who vanished

- Skill: data_cleaning; method: data-quality-audit; dataset: loan_book; difficulty 3; unlocks day 21
- Boss question: What is average balance by customer segment?
- Trap (join_mismatch): Customer IDs differ in format between the two tables, so a join silently drops customers.
- Dirt: join_mismatch
- Reference steps:
  1. Compare distinct keys in both tables
  2. Standardise keys (trim spaces, leading zeros)
  3. Join and compare the row count with the original
  4. Recompute by segment
- Correct findings:
  - After fixing key formats, {n_matched} of {n_total} accounts matched instead of {n_matched_raw}.
  - Average balance for {segment} was {avg_clean}.
- Wrong paths:
  - Use the joined table as is: Missing customers are not random, so the averages are biased.
  - Join on the customer name: Names are not unique or stable.
- Handbook: hb_join_keys, hb_text_standardize, hb_audit_first

## case_test_accounts: Staff signed up too

- Skill: data_cleaning; method: data-quality-audit; dataset: ab_test_log; difficulty 2; unlocks day 23
- Boss question: What is the conversion rate for new users this week? (forecast: up/down/flat)
- Trap (test_accounts): Internal and test accounts convert at unusual rates and distort the metric.
- Dirt: test_accounts
- Reference steps:
  1. Scan user IDs and emails for test patterns
  2. Check unusual activity per user
  3. Filter out confirmed test accounts and record the rule
  4. Recompute the conversion rate
- Correct findings:
  - After removing {n_test} test accounts, conversion was {rate_clean}, not {rate_raw}.
  - The exclusion rule was: {rule}.
- Wrong paths:
  - Keep everyone: Test accounts are not customers.
  - Remove all high-activity users: A real power user is not a test account.
- Handbook: hb_test_accounts, hb_assumptions_log, hb_audit_first

## case_subtotal_rows: The rows named Total

- Skill: data_cleaning; method: data-quality-audit; dataset: sales_export; difficulty 2; unlocks day 25
- Boss question: What was total revenue last month?
- Trap (double_counting_subtotals): Subtotal and repeated header rows sit inside the data, so a column sum counts some rows twice.
- Dirt: subtotal_rows, repeated_headers
- Reference steps:
  1. Scan for text in number columns
  2. Filter out repeated headers and total rows
  3. Sum the remaining rows
  4. Reconcile with the file's own grand total
- Correct findings:
  - Revenue was {rev_clean}, not {rev_raw}; {n_subtotals} subtotal rows and {n_headers} repeated headers were removed.
  - The cleaned sum matches the grand total in the file.
- Wrong paths:
  - Sum the whole column: Subtotals are included, inflating revenue.
  - Remove every row with a missing region: Some real rows may have a blank region.
- Handbook: hb_subtotal_rows, hb_double_counting, hb_audit_first

## case_negative_refunds: Refunds are not errors

- Skill: data_cleaning; method: data-quality-audit; dataset: sales_export; difficulty 2; unlocks day 27
- Boss question: What was net revenue in {region}, and did returns rise? (forecast: up/down/flat)
- Trap (refunds_vs_cancellations): Negative amounts are refunds that reduce revenue; cancelled orders are different and should not count as sales.
- Dirt: negative_values
- Reference steps:
  1. List negative amounts and statuses
  2. Separate refunds from cancellations
  3. Compute gross, refunds and net revenue
  4. Compare the refund rate with the previous period
- Correct findings:
  - Gross revenue was {gross}, refunds {refunds} and net {net}.
  - The refund rate moved from {rate_old} to {rate_new}.
- Wrong paths:
  - Drop negative rows as errors: That overstates revenue.
  - Count cancelled orders as sales: They never completed.
- Handbook: hb_refunds_cancellations, hb_double_counting, hb_audit_first

## case_truncated_export: The file that stopped in September

- Skill: data_cleaning; method: data-quality-audit; dataset: sales_export; difficulty 3; unlocks day 29
- Boss question: How did sales in the full year compare with last year? (forecast: up/down/flat)
- Trap (truncated_export): The export stopped at a row limit, so the last part of the year is missing.
- Dirt: truncated_export
- Reference steps:
  1. Check the first and last dates
  2. Check the row count for a round number
  3. Request a complete export or limit conclusions to the covered period
  4. Compare like periods only
- Correct findings:
  - The data ends on {last_date} at exactly {n_rows} rows; the comparison only covers {covered}.
  - A complete export is needed for a full-year claim.
- Wrong paths:
  - Compare the partial year to the full year: It will look like a collapse.
  - Extrapolate the missing months silently: State the assumption or ask for the data.
- Handbook: hb_truncated_export, hb_late_data, hb_audit_first

## case_competitor_scrape: Prices from a messy scrape

- Skill: data_cleaning; method: programmatic-eda; dataset: competitor_scrape; difficulty 3; unlocks day 30
- Boss question: Is the rival really cheaper than us on {item}? (forecast: down/flat/up)
- Trap (mixed_units_currency): Scraped prices mix pack sizes, currencies and promo labels, so raw prices are not comparable.
- Dirt: mixed_currency, mixed_units, category_typos, missing_values
- Reference steps:
  1. Standardise item names
  2. Convert prices to one currency
  3. Convert to price per unit (per kg or per piece)
  4. Handle missing and promo prices
  5. Compare medians
- Correct findings:
  - Per unit, the rival is {pct_diff} cheaper on {item} (median of {n} listings).
  - {n_excluded} listings were excluded for missing price.
- Wrong paths:
  - Compare raw prices: A bigger pack costs more but not per unit.
  - Compare means: A few extreme listings shift the mean; use the median.
- Handbook: hb_units_currency, hb_text_standardize, hb_mean_median

## case_data_rescue: The full rescue

- Skill: data_cleaning; method: data-quality-audit; dataset: sales_export; difficulty 5; unlocks day 31
- Boss question: We need a reliable weekly sales figure for {region} for the board. Can you provide it? (forecast: up/down/flat)
- Trap (multiple_defects): One file has several defects at once: duplicates, typos, zeros that mean missing, and an incomplete last day.
- Dirt: duplicates, category_typos, zero_as_null, late_arriving
- Reference steps:
  1. Audit: row counts, distinct keys, zeros, date range
  2. Remove duplicates
  3. Standardise region names
  4. Treat outage zeros as missing
  5. Exclude the partial last day
  6. Aggregate, compare with last week and log the assumptions
- Correct findings:
  - After {n_steps} cleaning steps, weekly units in {region} were {value}, {pct_change} versus last week.
  - Defects found: {defect_list}.
- Wrong paths:
  - Fix only the obvious defect: The remaining defects still move the answer.
  - Over-clean and delete anything odd: Real variation was removed, making the data look too smooth.
- Handbook: hb_plan, hb_audit_first, hb_duplicates, hb_text_standardize, hb_zero_vs_null, hb_late_data

## case_dual_axis: Two axes, one story

- Skill: charts; method: visualization-builder; dataset: market_prices; difficulty 4; unlocks day 32
- Boss question: Does the exchange rate drive our raw material cost? (forecast: up/down/flat)
- Trap (misleading_axis): A dual-axis chart with hand-picked scales makes two unrelated series look tightly linked.
- Dirt: none (analysis trap)
- Reference steps:
  1. Plot each series on its own chart
  2. Index both series to 100 at the same start date
  3. Compute the correlation over several windows
  4. State that the link is an association
- Correct findings:
  - Indexed to 100, the two series diverged by {gap} points after {date}.
  - The apparent link in the dual-axis chart depended on the axis scales.
- Wrong paths:
  - Keep the dual-axis chart: The scales were chosen to line the series up.
  - Conclude no relationship: Indexing shows partial co-movement; just no proof of cause.
- Handbook: hb_dual_axis, hb_corr_vs_cause, hb_line_time

## case_histogram_skew: The average that describes nobody

- Skill: charts; method: programmatic-eda; dataset: support_tickets; difficulty 3; unlocks day 33
- Boss question: What is the typical ticket resolution time?
- Trap (mean_vs_median): Resolution times are strongly skewed; a few very long tickets drag the mean far above the typical time.
- Dirt: none (analysis trap)
- Reference steps:
  1. Draw a histogram of resolution times
  2. Compare mean and median
  3. Report the median and a high percentile
  4. Segment slow tickets by category
- Correct findings:
  - The median resolution time was {median}, while the mean was {mean} because of {n_long} very long tickets.
  - Slow tickets cluster in {category}.
- Wrong paths:
  - Report the mean only: It describes neither the typical nor the slow tickets.
  - Delete the long tickets: They are real and important.
- Handbook: hb_mean_median, hb_histogram, hb_segmentation
