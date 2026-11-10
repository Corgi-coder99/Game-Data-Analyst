# Analyst Handbook (T-035a)

Fictional examples only. Source of truth: `data/handbook.json`.

Total cards: 49.

## Skill: data_cleaning

### Audit before you analyse (`hb_audit_first`)

A data audit is a quick first look at a file: how many rows, which columns, what is blank, what repeats, what looks odd. It tells you whether the numbers can be trusted before you build anything on them.

- When to use: Every time you open a new file, before any chart or total.
- Common mistakes:
  - Jumping straight to a total or chart and trusting it
  - Only looking at the first few rows
  - Fixing things silently without writing down what you changed
- Example: A sales file has 120 rows but only 3 distinct dates for a 7-day week. That gap is a finding: either the export is truncated or days are missing.
- In the game: Open the file in the Sheet, check the row count, sort each column, and look at the preview before adding any step.
- See also: hb_duplicates, hb_missing_values, hb_assumptions_log

### Duplicate rows (`hb_duplicates`)

A duplicate is the same record appearing more than once, often because an export was run twice. If you add up duplicated rows, totals come out too big.

- When to use: When row counts look high, or the same ID, date and amount appear together twice.
- Common mistakes:
  - Removing rows that only look alike but are genuine repeat purchases
  - Deduplicating on one column when the real key is several columns
  - Forgetting to deduplicate before summing
- Example: Order 1041, 3 units, 2 March appears twice. The raw total is 40 units, but one of those rows is a copy, so the true total is 37.
- In the game: Use the Remove duplicates step and pick the key columns (for example order_id plus date). Check the row count before and after.
- See also: hb_double_counting, hb_audit_first

### Missing values (`hb_missing_values`)

A missing value is a cell with no information: blank, N/A, null or a placeholder. You can drop the row, fill it with a reasonable value, or leave it out of the calculation, but you must choose on purpose.

- When to use: When a column has blanks or placeholders such as N/A or a dash.
- Common mistakes:
  - Filling with the average without asking why it is missing
  - Dropping so many rows that the sample becomes biased
  - Not noticing that different spellings (blank, N/A, none) mean the same thing
- Example: Prices for 4 of 20 shops are blank. Dropping them leaves 16 shops, but if the blanks are all the cheapest shop type, the average price is now too high.
- In the game: Use Handle missing: drop, fill with a value, fill with median, or fill with previous value. Look at the preview first.
- See also: hb_zero_vs_null, hb_survivorship

### Zero is not the same as missing (`hb_zero_vs_null`)

A real zero means something was measured and the answer was none. A missing value means nobody measured it. Exports often write 0 when the data is simply absent.

- When to use: When a numeric column suddenly shows many zeros, especially on one day or one region.
- Common mistakes:
  - Averaging the fake zeros and dragging the mean down
  - Treating every zero as an error, even real zero sales
  - Not asking the data owner what a zero means
- Example: A shop reports units of 12, 15, 0, 14. If the 0 means the till was offline, the average is 13.7 units over the three good days, not 10.25 over four.
- In the game: Filter the zeros, compare them with neighbouring rows and other sources, then use Handle missing to treat them as blanks if they are not real.
- See also: hb_missing_values, hb_audit_first

### Units and currency (`hb_units_currency`)

A column can mix units: thousands and millions, kilograms and grams, local money and dollars. Numbers are only comparable after you convert them to one unit.

- When to use: When values in one column differ by factors of 10, 100 or 1000, or when a unit or currency column has more than one value.
- Common mistakes:
  - Converting only some rows
  - Using today's exchange rate for old rows without saying so
  - Mixing percent (12) with fractions (0.12)
- Example: Revenue shows 2.5 (in millions) next to 2,400,000 (in plain units). Both are about the same size. Convert both to millions before adding.
- In the game: Use Convert unit/currency, then Add computed column to apply the factor to the rows that need it. Check the unit column afterwards.
- See also: hb_entry_error_vs_spike, hb_percent_points

### Dates and time zones (`hb_dates_timezones`)

Dates arrive in many formats and time zones. 03/04 may be 3 April or 4 March, and a late-evening sale in one time zone is already tomorrow in another.

- When to use: When a date column has more than one pattern, or day totals look odd around midnight.
- Common mistakes:
  - Guessing the day and month order
  - Ignoring time zones when comparing two sources
  - Sorting dates as text so that 10 Mar comes before 2 Mar
- Example: A row reads 05/06/2026. If other rows read 25/06/2026, the format is day first, so this one is 5 June.
- In the game: Use Parse date, tell it the format, then sort by the parsed date. Check the earliest and latest dates.
- See also: hb_late_data, hb_audit_first

### Standardise text categories (`hb_text_standardize`)

The same category can be typed many ways: Hanoi, Ha Noi, hanoi. A group-by treats each spelling as a separate group, which splits one real group into pieces.

- When to use: Before grouping or counting by a text column.
- Common mistakes:
  - Merging two categories that really are different
  - Fixing the top spelling but leaving rare ones
  - Forgetting extra spaces and capital letters
- Example: Hanoi has 40 units, Ha Noi has 30 and hanoi has 10. The real total for Hanoi is 80, which may change which region ranks first.
- In the game: Use Standardize text to merge variants. Group by the column and read the list of groups to spot leftovers.
- See also: hb_audit_first, hb_join_keys

### Outliers and the IQR rule (`hb_outliers_iqr`)

An outlier is a value far from the rest. A common rule: sort the data, find Q1 (the 25% mark) and Q3 (the 75% mark), and call a value an outlier if it is below Q1 - 1.5 x IQR or above Q3 + 1.5 x IQR, where IQR = Q3 - Q1. The rule only flags values; you decide what they are.

- When to use: To find values worth a closer look before taking averages or drawing charts.
- Common mistakes:
  - Deleting every flagged value automatically
  - Applying the rule to naturally skewed data without checking
  - Running the rule on a tiny sample
- Example: Values: 10, 11, 12, 12, 13, 14, 15, 16, 90. Q1 is 11.5, Q3 is 15.5 (medians of the lower and upper halves), IQR is 4, so the upper fence is 15.5 + 6 = 21.5. Only 90 is flagged.
- In the game: Use Flag outliers with the IQR rule and read the preview. Then decide: fix, remove or keep.
- See also: hb_entry_error_vs_spike, hb_mean_median

### Entry error or real spike? (`hb_entry_error_vs_spike`)

A strange value is either a typing mistake or a real event. Entry errors are usually isolated, off by a clean factor (an extra zero), and not confirmed elsewhere. Real spikes persist, show up in related columns or other sources, and have a story.

- When to use: When a value is far above or below its neighbours.
- Common mistakes:
  - Deleting real events because they look odd
  - Keeping obvious typos and letting them wreck the average
  - Not checking a second source
- Example: Steel price over 6 days: 150, 151, 1520, 152, 153, 152. The jump lasts one day and is exactly 10 times the neighbours: likely an extra zero. A move to 170 that stays at 170 for days is more likely real.
- In the game: Chart the series as a line, then check neighbours, a second source or the news. Fix the typo, keep the real change.
- See also: hb_outliers_iqr, hb_line_time

### Test and internal accounts (`hb_test_accounts`)

Staff and test accounts use the product but are not real customers. They can inflate counts or create fake behaviour such as dozens of tiny purchases.

- When to use: When user lists contain names like test, demo or admin, or a few IDs show huge activity.
- Common mistakes:
  - Leaving test users in conversion numbers
  - Removing a real power user because they look unusual
  - Not documenting the rule used to exclude them
- Example: 12 of 500 signups come from test_01 to test_12. Without them there are 488 real signups, and the conversion rate changes.
- In the game: Use Filter on the user column, check the preview count, and note the rule in your report.
- See also: hb_assumptions_log, hb_audit_first

### Headers and total rows inside data (`hb_subtotal_rows`)

Some exports repeat the header line or include subtotal and grand-total rows in the middle of the data. If you sum the whole column, these rows are counted twice.

- When to use: When a column sum looks about double what you expect, or text appears in a number column.
- Common mistakes:
  - Summing a column that includes a Total row
  - Leaving repeated header rows that turn numbers into text
  - Removing a row that is a real category named Total
- Example: Rows: A 10, B 20, Total 30. A sum of all three is 60, but the real total is 30.
- In the game: Use Filter to remove rows where a key column equals Total or repeats the header text.
- See also: hb_double_counting, hb_audit_first

### Late-arriving data (`hb_late_data`)

The most recent day or hour is often incomplete because records are still arriving. Comparing a partial day with full days makes things look like they dropped.

- When to use: When the last period is much lower than the others or the export time is earlier than the end of the period.
- Common mistakes:
  - Reading the last partial day as a real drop
  - Averaging a partial day with full days
  - Not checking the export timestamp
- Example: Sales per day: 100, 104, 98, 102, then 31 at 10:00 on the last day. The 31 is a half-built day, not a crash.
- In the game: Check the export time, then Filter out the incomplete period or label it as partial in your chart.
- See also: hb_dates_timezones, hb_truncated_export

### Join keys that do not match (`hb_join_keys`)

A join links two tables on a shared key, like customer_id. If the keys differ in format or are missing in one table, rows silently disappear or multiply.

- When to use: Whenever you combine two tables.
- Common mistakes:
  - Not checking how many rows matched
  - Joining on a name instead of an ID
  - Ignoring leading zeros or extra spaces in keys
- Example: Table A has ID 007 and table B has 7. The join finds no match for that customer, and the customer vanishes from the result.
- In the game: Use Lookup/join, then compare the row count to the original and look for blanks in the new columns.
- See also: hb_text_standardize, hb_audit_first

### Truncated exports (`hb_truncated_export`)

A truncated export stops early, often at a round number of rows or at a size limit. Everything after the cut is missing, and the file may not tell you.

- When to use: When the row count is suspiciously round (1000, 65536) or the data stops in the middle of a period.
- Common mistakes:
  - Assuming the file is complete
  - Analysing only the earlier part and presenting it as the whole
  - Not asking for a fresh export
- Example: A year of orders ends on 14 September with exactly 10,000 rows. The cut happened at the limit, so the rest of the year is missing.
- In the game: Sort by date, look at the last rows and the count, and flag the gap in your findings.
- See also: hb_late_data, hb_audit_first

### Refunds and cancellations (`hb_refunds_cancellations`)

Negative amounts are often refunds, which are real events that reduce revenue. Cancelled orders are orders that never completed. They are different things and need different handling.

- When to use: When a money column has negative values or a status column has cancelled.
- Common mistakes:
  - Dropping negative rows and overstating revenue
  - Counting cancelled orders as sales
  - Treating a refund as a data error
- Example: Sales of 100 and 80, then a refund of -30. Net revenue is 150, not 180.
- In the game: Filter by status for cancellations; keep negative amounts when you want net revenue. Say which one you report.
- See also: hb_subtotal_rows, hb_audit_first

### Double counting (`hb_double_counting`)

Double counting means the same thing is included twice, through duplicate rows, overlapping groups or a subtotal added to its parts. It makes totals and percentages too big.

- When to use: When parts add up to more than the whole, or when merging overlapping lists.
- Common mistakes:
  - Adding up groups that overlap, such as users in two segments
  - Adding subtotals to the rows they summarise
  - Counting the same customer from two systems
- Example: A shop has 60 web customers and 50 app customers, but 20 use both. Unique customers are 90, not 110.
- In the game: Count unique IDs with Remove duplicates and Group by count. Compare the parts to the total.
- See also: hb_duplicates, hb_subtotal_rows

## Skill: statistics

### Mean versus median (`hb_mean_median`)

The mean adds everything and divides by the count. The median is the middle value when sorted. One huge value drags the mean a lot but barely moves the median.

- When to use: Whenever you summarise a column that might have extreme values, such as prices, incomes or delivery times.
- Common mistakes:
  - Reporting the mean of a very skewed column
  - Forgetting to say which one you used
  - Assuming mean and median are close
- Example: Five salaries: 30, 32, 35, 36, 300. The mean is 86.6 and the median is 35. The median describes the typical person better here.
- In the game: In Group by + aggregate, choose median as well as mean and compare. A big gap is a warning sign.
- See also: hb_outliers_iqr, hb_histogram

### Small samples are noisy (`hb_noise_sample`)

With few observations, random chance can produce big swings. A 50% rate from 4 users is far less reliable than 50% from 4,000 users.

- When to use: Any time you compare rates or averages from small groups.
- Common mistakes:
  - Celebrating a big change from a handful of cases
  - Ranking small groups against large ones
  - Not showing how many cases each number is based on
- Example: Shop A: 2 of 3 customers returned (67%). Shop B: 600 of 1,000 returned (60%). Shop A is not clearly better; its number is shaky.
- In the game: Always add a count column next to a rate. Treat groups below about 30 cases with caution.
- See also: hb_confidence_interval, hb_pvalue

### What a p-value means (`hb_pvalue`)

A p-value answers: if there were really no difference, how often would random luck alone produce a gap at least this big? A small p-value (below 0.05 by common convention) means luck is an unlikely explanation. It does not tell you the chance that you are right, or how large or important the effect is.

- When to use: When comparing two groups, as in an A/B test.
- Common mistakes:
  - Saying p = 0.04 means a 96% chance the change works
  - Treating p = 0.06 as proof of no effect
  - Ignoring the size of the effect
  - Testing many things and reporting only the significant one
- Example: Variant A converts 20 of 200 users (10%). Variant B converts 34 of 200 (17%). The two-sided p-value is about 0.04, so a gap this big would be uncommon if there were no real difference.
- In the game: Check the test result panel for p and the count per variant. Report both the gap and whether it is significant.
- See also: hb_ab_test, hb_confidence_interval

### Confidence intervals (`hb_confidence_interval`)

A 95% confidence interval is a range built by a method that, over many repeated studies, captures the true value about 95% of the time. A wide interval means you are uncertain.

- When to use: To show how precise an estimate is, not just a single number.
- Common mistakes:
  - Saying there is a 95% chance the true value is inside this one range
  - Ignoring a very wide range
  - Comparing intervals only by eye
- Example: A conversion rate of 10% from 100 users has a 95% interval of roughly 5% to 18%. From 10,000 users it is roughly 9.4% to 10.6%.
- In the game: When the report shows a rate, add a count and mention the range if the sample is small.
- See also: hb_noise_sample, hb_sample_size

### How many users do you need? (`hb_sample_size`)

Before a test, decide the smallest change you care about and how sure you want to be. Smaller changes need many more users. A test that is too small will often miss real effects.

- When to use: Before running or trusting an A/B test.
- Common mistakes:
  - Stopping when the numbers look good
  - Expecting a tiny change to show up with a few hundred users
  - Forgetting that the sample is needed per group
- Example: To detect a rise from 10% to 12% with 80% power at the 5% significance level, you need roughly 3,800 users per variant.
- In the game: Compare the users per variant in the log with the size suggested in the case hint. If you are short, say the test is underpowered.
- See also: hb_ab_test, hb_peeking

### A/B tests in a nutshell (`hb_ab_test`)

In an A/B test, users are randomly split into groups, each sees a different version, and you compare an outcome such as conversion. Random assignment is what lets you say the version caused the difference.

- When to use: To decide between two versions of something.
- Common mistakes:
  - Comparing groups that were not randomly assigned
  - Changing several things at once
  - Looking only at the winner and ignoring group sizes
- Example: A: 20 of 200 (10%). B: 34 of 200 (17%). The gap is 7 points. Check that the groups are about equal size and that p is small.
- In the game: Group by variant, count users, compute conversion, then read the significance check.
- See also: hb_pvalue, hb_peeking, hb_sample_size

### Peeking at A/B tests (`hb_peeking`)

If you check a running test again and again and stop the first time p is below 0.05, you will find false winners far more often than 5%. With ten looks the false alarm rate is closer to one in five.

- When to use: When someone asks to stop a test early because it looks good.
- Common mistakes:
  - Stopping on the first significant result
  - Extending the test only when the result is disappointing
  - Not fixing the sample size in advance
- Example: A test with no real difference is checked 10 times. Roughly 1 in 5 such tests will show p below 0.05 at some look.
- In the game: Set the sample size first and read the result once at the end, or treat early reads as provisional.
- See also: hb_sample_size, hb_pvalue

### Seasonality versus trend (`hb_seasonality`)

Seasonality is a repeating pattern, such as weekend peaks or December sales. A trend is a steady change in the level. Comparing a seasonal peak with an off-season month can look like growth when it is only the calendar.

- When to use: When comparing periods in a time series.
- Common mistakes:
  - Comparing December with January and calling it a crash
  - Comparing with the previous month instead of the same month last year
  - Fitting a straight line through a seasonal pattern
- Example: Sales are 150 in December and 100 in January every year. This January against last January is the fair comparison.
- In the game: Line chart with several years overlaid, or compare to the same period last year using Add computed column.
- See also: hb_line_time, hb_moving_average

### Base rates (`hb_base_rate`)

The base rate is how common something is to begin with. When the thing is rare, even an accurate alarm gives mostly false alarms.

- When to use: When a test, alert or flag points at a rare event.
- Common mistakes:
  - Ignoring how rare the event is
  - Reading a 90% accurate flag as a 90% chance
  - Not counting false alarms
- Example: Fraud affects 1% of 1,000 payments, so 10 are fraud. The alarm catches 9 of them and falsely flags 99 of the 990 honest ones. Of 108 flags, only 9 (about 8%) are real fraud.
- In the game: Build a small table: total, real cases, flagged real, flagged false. Use Group by count.
- See also: hb_noise_sample, hb_report_findings

### Regression to the mean (`hb_regression_mean`)

Extremely high or low results tend to be followed by more average ones, because extreme values contain a lot of luck. A fix applied right after a terrible week can look effective when nothing changed.

- When to use: When you pick the worst or best performers and measure again.
- Common mistakes:
  - Crediting a fix for a natural bounce-back
  - Rewarding or blaming people for random swings
  - Selecting extremes and comparing them without a control group
- Example: The 5 shops with the lowest sales last month improve by 8% this month without any action, because last month included bad luck.
- In the game: Chart several periods, not one. Compare treated shops with similar untreated shops.
- See also: hb_noise_sample, hb_corr_vs_cause

### Percent versus percentage points (`hb_percent_points`)

A change from 10% to 12% is 2 percentage points but a 20% relative increase. Both are true, but they sound very different, so always say which one you mean.

- When to use: Whenever you describe a change in a rate.
- Common mistakes:
  - Saying the rate rose 2% when you mean 2 points
  - Hiding a tiny absolute change behind a large relative one
  - Averaging percentages without weights
- Example: Conversion goes from 5.0% to 5.5%: +0.5 points, or +10% relative.
- In the game: Use Add computed column for both the difference and the ratio, and label them clearly.
- See also: hb_units_currency, hb_report_findings

## Skill: charts

### Choosing a chart (`hb_choose_chart`)

Match the chart to the question. Line for change over time, bar for comparing categories, scatter for the link between two numbers, histogram for how values are spread.

- When to use: Before you build any chart.
- Common mistakes:
  - Using pie for many slices
  - Using a line for unordered categories
  - Choosing a chart because it looks fancy
- Example: Question: which of 3 regions sold most? Use a sorted bar chart. Question: how did price change over 30 days? Use a line.
- In the game: In Chart builder, pick the type that fits the question and set a clear axis title with units.
- See also: hb_bar_axis, hb_line_time, hb_scatter

### Bar charts start at zero (`hb_bar_axis`)

A bar's length stands for its value, so the axis must start at zero. If it starts higher, small differences look huge.

- When to use: Whenever you make a bar chart.
- Common mistakes:
  - Cutting the axis to make a change look dramatic
  - Not labelling the axis
  - Leaving bars in random order
- Example: Sales of 98 and 102 on a chart that starts at 96 make one bar look three times as tall as the other. On a zero axis they look nearly equal, which is the truth.
- In the game: In Chart builder, keep the Y-axis minimum at zero for bars. The quality checker will warn if you truncate it.
- See also: hb_choose_chart, hb_sort_label

### Line charts for time (`hb_line_time`)

A line chart connects points in time order, so you can see trend, jumps and seasonality. Time goes left to right, with equal spacing.

- When to use: To show how a measure changes over days, weeks or months.
- Common mistakes:
  - Connecting points that are not in time order
  - Smoothing so much that real spikes vanish
  - Skipping missing days without showing the gap
- Example: Weekly sales: 100, 105, 98, 160, 102. The line shows a one-week spike at 160 that an overall average would hide.
- In the game: Group by date, then use Chart builder with the date on X and the measure on Y.
- See also: hb_moving_average, hb_seasonality

### Scatter plots (`hb_scatter`)

A scatter plot puts one number on each axis, one dot per item, to show whether two measures move together. It shows association, not cause.

- When to use: To explore the link between two numeric columns.
- Common mistakes:
  - Concluding that one causes the other
  - Ignoring a few extreme dots that create the pattern
  - Plotting too many dots on top of each other
- Example: Across 12 cities, ice cream sales and sunburn cases rise together. A scatter shows the pattern, but hot weather drives both.
- In the game: Chart builder, scatter type, choose X and Y. Check for outliers before reading the pattern.
- See also: hb_corr_vs_cause, hb_confounder

### Histograms (`hb_histogram`)

A histogram groups values into ranges and shows how many fall in each. It reveals the shape of the data: tight, skewed or with two humps.

- When to use: To see how a column is spread before deciding between mean and median.
- Common mistakes:
  - Using too few or too many bins
  - Confusing it with a bar chart of categories
  - Forgetting the vertical axis is a count
- Example: Delivery times with two humps, one near 2 days and one near 9 days, suggest two different processes mixed together.
- In the game: Chart builder, histogram, pick the column and try two bin widths.
- See also: hb_mean_median, hb_segmentation

### Dual axes and misleading scales (`hb_dual_axis`)

A dual-axis chart puts two different scales on one picture. By choosing the scales you can make any two lines look closely linked or completely different.

- When to use: Rarely. Prefer two small charts side by side.
- Common mistakes:
  - Picking scales so the lines line up
  - Not labelling which axis belongs to which line
  - Reading a link from the picture alone
- Example: Sales (0 to 1000) and ad spend (0 to 5) drawn on separate axes can look like twins even if they are unrelated.
- In the game: Use two charts, or index both to 100 at the start. The quality checker flags dual-axis use.
- See also: hb_bar_axis, hb_corr_vs_cause

### Pie charts: use with care (`hb_pie_caution`)

A pie shows parts of one whole, but people judge angles poorly. With many slices or similar sizes, a sorted bar chart is clearer.

- When to use: Only for two or three parts of a whole that adds to 100%.
- Common mistakes:
  - Using a pie for more than five slices
  - Using a pie for things that do not add to a whole
  - Adding 3D effects
- Example: Five regions with shares of 22%, 21%, 20%, 19% and 18% are hard to rank in a pie but easy in a sorted bar.
- In the game: Choose bar instead of pie in Chart builder unless there are just two or three parts.
- See also: hb_choose_chart, hb_sort_label

### Sort, label, and give units (`hb_sort_label`)

A clear chart has a title that states the point, labelled axes with units, bars sorted by size when order does not matter, and a source note. A reader should not have to guess.

- When to use: On every chart that goes into a report.
- Common mistakes:
  - Leaving units off the axis
  - Sorting alphabetically so nobody can rank
  - Using a title like Chart 1
- Example: Title: Hanoi sold 120 units, the most of three regions (units per week). That tells the reader the point.
- In the game: Set title, axis labels and sort in Chart builder. The checker warns about missing units.
- See also: hb_bar_axis, hb_report_findings

### Moving averages (`hb_moving_average`)

A moving average replaces each point by the average of the last few points. It smooths noise so a trend is easier to see, but it also blurs sudden jumps.

- When to use: To see the underlying trend in a noisy daily series.
- Common mistakes:
  - Using a window so wide that real spikes disappear
  - Forgetting that the first few points have no full window
  - Treating the smoothed line as the raw data
- Example: Daily sales 10, 14, 9, 13, 10, 14, 9. The 3-day average stays between 11 and 12, showing no real trend.
- In the game: Add computed column, choose moving average with a window of 3 or 7, and chart both lines.
- See also: hb_line_time, hb_seasonality

## Skill: causality

### Correlation is not causation (`hb_corr_vs_cause`)

Two things moving together does not mean one causes the other. A third factor may drive both, the link may be chance, or the cause may run the other way.

- When to use: Whenever you see two measures that rise or fall together.
- Common mistakes:
  - Announcing a cause from a chart
  - Ignoring a hidden third factor
  - Assuming that the order of events proves the cause
- Example: Across 12 cities, those with 2x the ice cream sales have more sunburn. Sunshine drives both; banning ice cream will not cure sunburn.
- In the game: Use a scatter to see the link, then look for a third factor by splitting with Group by. Word findings as 'is associated with'.
- See also: hb_confounder, hb_scatter, hb_ab_test

### Confounders (`hb_confounder`)

A confounder is a third factor that affects both the thing you change and the outcome, creating a false or distorted link. Random assignment in a test removes most confounding.

- When to use: When groups differ in more than the thing you are studying.
- Common mistakes:
  - Comparing groups that differ in age, region or device mix
  - Not checking group makeup
  - Assuming adjustment fixes everything
- Example: App users spend 35 per order versus 20 for others, but they are also younger and richer. The app may not be the reason.
- In the game: Split by the suspected factor with Group by and compare like with like.
- See also: hb_simpson, hb_corr_vs_cause

### Simpson's paradox (`hb_simpson`)

Sometimes one option wins inside every subgroup but loses overall, because the groups are mixed in different proportions. Always check whether a split changes the story.

- When to use: When overall results and subgroup results seem to disagree, or when groups have very different sizes.
- Common mistakes:
  - Trusting the overall total without splitting
  - Always trusting the split without thinking about which one answers your question
  - Not checking how the groups are weighted
- Example: Variant A: 160 of 800 desktop (20%), 8 of 200 mobile (4%), total 16.8%. Variant B: 44 of 200 desktop (22%), 40 of 800 mobile (5%), total 8.4%. B wins on both devices but loses overall, because B got mostly mobile users.
- In the game: Group by variant and by device, then compare rates within each device.
- See also: hb_confounder, hb_segmentation

### Survivorship bias (`hb_survivorship`)

Survivorship bias happens when you only look at what survived, so failures are missing from the data. The picture is too rosy.

- When to use: When a dataset only lists active, open or successful items.
- Common mistakes:
  - Studying only current customers to explain churn
  - Judging a strategy only by its winners
  - Not asking what was filtered out before you got the file
- Example: A loan book lists only open accounts. Defaulted accounts were removed, so the default rate looks like 0%.
- In the game: Ask what is missing, look for status columns, and request the closed records if you can.
- See also: hb_cohort, hb_audit_first

### Cherry-picking (`hb_cherry_pick`)

Cherry-picking means showing only the data points that support a story, such as a lucky date range. The facts are real but the picture is false.

- When to use: When someone gives you a time window or subset you did not choose.
- Common mistakes:
  - Choosing start and end dates to get the trend you want
  - Reporting the best of many tests
  - Leaving out the periods that disagree
- Example: Sales are up 30% from a weak Tuesday to a strong Friday, yet down 5% over the full month.
- In the game: Chart the full range and say why any window was chosen before you saw the result.
- See also: hb_seasonality, hb_assumptions_log

## Skill: communication

### Funnel analysis (`hb_funnel`)

A funnel counts how many users reach each step of a journey, for example visit, sign-up, purchase. The step with the biggest proportional drop is the first place to look for a problem.

- When to use: To find where users give up in a process.
- Common mistakes:
  - Comparing step drops in raw numbers instead of percentages
  - Mixing users from different days into one step
  - Ignoring an incomplete last day
- Example: 1,000 visit, 300 start sign-up, 240 finish, 60 buy. Step rates: 30%, 80%, 25%. The weakest step after the first is finish to buy (25%).
- In the game: Group by step, compute the rate from each step to the next, and chart as a sorted bar.
- See also: hb_late_data, hb_segmentation

### Cohort retention (`hb_cohort`)

A cohort is a group of users who started in the same period. Retention is the share of the cohort still active after 1 week, 2 weeks, and so on. It compares like with like, so growth in new users does not hide churn.

- When to use: To judge whether customers stick around, or whether a change helped retention.
- Common mistakes:
  - Mixing old and new users in one retention number
  - Comparing cohorts of different ages
  - Forgetting closed accounts
- Example: Of 200 users who joined in January, 120 were active in week 1 and 80 in week 4. Week-4 retention is 40%.
- In the game: Add a computed column for start month and weeks since start, then Pivot cohort by week.
- See also: hb_survivorship, hb_funnel

### Segmentation (`hb_segmentation`)

Segmentation splits users into groups that behave differently, such as by region, device or spending. An average over everyone can hide what each segment is doing.

- When to use: When the average seems to hide something, or when different groups need different actions.
- Common mistakes:
  - Making too many tiny segments
  - Choosing segments after seeing the result to fit a story
  - Forgetting group sizes
- Example: Average basket is 20. New customers spend 12 and loyal customers spend 35. One average describes neither group.
- In the game: Group by the segment column with count and mean, and compare.
- See also: hb_simpson, hb_noise_sample

### Root-cause drill-down (`hb_root_cause`)

When a metric changes, split it step by step: by time, region, product, channel. Keep drilling into the part that moved most until you find the source. Then check that the explanation covers the whole change.

- When to use: When the boss asks why something went up or down.
- Common mistakes:
  - Stopping at the first plausible reason
  - Explaining the change with a story that fits only part of it
  - Not checking whether the change is really a data issue
- Example: Revenue fell 10%. Split by region: only Hue fell, by 40%. Split Hue by product: one product was out of stock.
- In the game: Group by one dimension at a time, compare with the previous period, and chart the biggest changes.
- See also: hb_segmentation, hb_audit_first

### Plan the analysis (`hb_plan`)

Before touching data, write the question, the metric, the comparison and what result would change your mind. This stops you wandering and fitting a story afterwards.

- When to use: At the start of any case.
- Common mistakes:
  - Starting with a chart and hunting for a story
  - Using a metric you did not define
  - Changing the question after seeing the data
- Example: Question: did sales rise this week? Metric: units per day. Comparison: previous 7 days. Decision: call it a rise if more than 5% higher.
- In the game: Read the boss question, note the metric and the comparison, then choose the files and steps.
- See also: hb_audit_first, hb_report_findings

### Keep an assumptions log (`hb_assumptions_log`)

An assumptions log is a short list of choices you made, such as 'removed test accounts' or 'treated zeros as missing'. It lets others check your work and explains differences between analysts.

- When to use: Any time you make a judgement call in cleaning or analysis.
- Common mistakes:
  - Making silent fixes
  - Writing vague notes
  - Forgetting the assumptions when you set confidence
- Example: Assumption: the 0 units on 4 March means the till was offline, so it is treated as missing.
- In the game: The step list in the Sheet is your log. Add a short note in your report for each non-obvious step.
- See also: hb_audit_first, hb_report_findings

### Write clear findings (`hb_report_findings`)

A good finding states what you measured, how big the change is, what comparison you used, and how sure you are. Keep it short and avoid claims the data cannot support.

- When to use: When filling in the report.
- Common mistakes:
  - Overstating certainty
  - Reporting only the number without the comparison
  - Hiding the limits of the data
- Example: Weak: Sales are up. Strong: Units are 8% higher than the previous 7 days (310 vs 287), based on 14 stores, after removing duplicate rows.
- In the game: Pick the findings that match your cleaned table and attach at most three pieces of evidence.
- See also: hb_confidence_calibration, hb_plan

### Confidence means honesty (`hb_confidence_calibration`)

Confidence is how sure you are, not how bold you sound. Over time, your 70% answers should be right about 70% of the time. Dirty data, small samples and untested assumptions all lower honest confidence.

- When to use: When you set the confidence level in your report.
- Common mistakes:
  - Always choosing high confidence
  - Always choosing low confidence to be safe
  - Not lowering confidence when the data was dirty or small
- Example: You make ten forecasts at 70% confidence and 7 come true: that is well calibrated.
- In the game: After cleaning, ask: how many rows, how clean, is the test significant? Then set the confidence slider.
- See also: hb_noise_sample, hb_report_findings
