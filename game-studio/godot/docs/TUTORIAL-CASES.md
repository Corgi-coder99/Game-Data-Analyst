# Tutorial cases: 5-day onboarding ladder (T-035a)

Fictional data. For T-035 to implement a guided tutorial. Each day: goal, file (CSV), raw defects, expected steps, expected findings, handbook cards. Steps use the Sheet operation names from `docs/DESIGN-data-core.md` section 4. Numbers were computed by script and are exact.

General tutorial rules: show one hint at a time; the player may skip hints; the hint button points to a Handbook card, never the answer; after the correct pipeline the review shows the dirt manifest.

## Day 1: The double export (duplicates and spelling variants)

- Case ids: `case_duplicate_export`, `case_category_typos`. Dataset: sales_export. Boss question: Which region sold the most units this week?
- Learning goals: open a file and look before trusting it; remove duplicates using a full key; standardise text categories; group by and sort.
- Cards: hb_audit_first, hb_duplicates, hb_text_standardize.

File `sales_export_day1.csv` (14 rows):

```csv
date,region,product,units,price,currency,channel
2026-03-02,Hanoi,Tea Box,30,4.0,USD,web
2026-03-02,Da Nang,Tea Box,25,4.0,USD,web
2026-03-02,Hue,Tea Box,22,4.0,USD,web
2026-03-03,Ha Noi,Tea Box,28,4.0,USD,web
2026-03-03,Da Nang,Tea Box,27,4.0,USD,web
2026-03-03,Da Nang,Tea Box,27,4.0,USD,web
2026-03-03,Hue,Tea Box,20,4.0,USD,web
2026-03-04,hanoi,Tea Box,32,4.0,USD,web
2026-03-04,Da Nang,Tea Box,26,4.0,USD,web
2026-03-04,Da Nang,Tea Box,26,4.0,USD,web
2026-03-04,Hue,Tea Box,21,4.0,USD,web
2026-03-05,Hanoi,Tea Box,30,4.0,USD,web
2026-03-05,Da Nang,Tea Box,24,4.0,USD,web
2026-03-05,Hue,Tea Box,23,4.0,USD,web
```

Defects (dirt manifest): 2 exact duplicate rows (Da Nang on 03-03 and 03-04); 2 spelling variants of Hanoi (`Ha Noi`, `hanoi`).

Expected steps:
1. Inspect: 14 rows, 3 regions expected.
2. Remove duplicates, key = all columns (or date + region + product). Rows 14 to 12.
3. Standardize text on region: `Ha Noi`, `hanoi` become `Hanoi`.
4. Group by region, sum units, sort descending.
5. Chart: sorted bar, Y-axis from zero, title with units.

Expected findings:
- Hanoi sold the most: 120 units; Da Nang 102; Hue 86. Total 308 units.
- Raw (naive) group-by wrongly puts Da Nang first with 155 units because of duplicates, while Hanoi is split across 3 spellings (60, 28, 32). Raw total 361 is overstated by 53 units.
- Wrong paths to catch: summing the raw data (Da Nang first, total overstated); removing duplicates but not merging Hanoi (Da Nang is still wrongly first with 102 units, because Hanoi stays split into 60, 28 and 32).

## Day 2: One extra zero (entry error versus real move)

- Case id: `case_entry_error_vs_spike`. Dataset: market_prices. Boss question: Will the steel index rise, fall or stay flat next week?
- Learning goals: line chart first; IQR rule flags values, you decide; an isolated 10x value is a typo, a persistent step is real; do not delete real information.
- Cards: hb_line_time, hb_outliers_iqr, hb_entry_error_vs_spike.

File `market_prices_day2.csv` (14 rows, weekdays):

```csv
date,series,value,unit,source
2026-03-02,Steel index,148,points,exchange
2026-03-03,Steel index,149,points,exchange
2026-03-04,Steel index,150,points,exchange
2026-03-05,Steel index,151,points,exchange
2026-03-06,Steel index,150,points,exchange
2026-03-09,Steel index,1520,points,exchange
2026-03-10,Steel index,152,points,exchange
2026-03-11,Steel index,153,points,exchange
2026-03-12,Steel index,152,points,exchange
2026-03-13,Steel index,171,points,exchange
2026-03-16,Steel index,172,points,exchange
2026-03-17,Steel index,170,points,exchange
2026-03-18,Steel index,171,points,exchange
2026-03-19,Steel index,173,points,exchange
```

Defects: one entry error (1520 on 03-09, neighbours 150 and 152). Not a defect: the move up to about 171 from 03-13 persists for 5 days.

Expected steps:
1. Line chart of value by date.
2. Flag outliers by IQR (the Sheet Outliers step, k = 1.5): Q1 = 150.25, Q3 = 171, IQR = 20.75, upper fence = 202.1, lower fence = 119.1. Only 1520 is flagged. (T-035: the engine uses linear-interpolation quartiles, not median-of-halves; see the note at the end.)
3. Decide: 1520 is exactly 10x its neighbours and appears once: fix to 152 (or mark missing and fill with previous value).
4. Keep 03-13 onward (171 to 173): not flagged and persistent.
5. Recompute the mean or chart again.

Expected findings:
- The 03-09 value 1520 is a data-entry error (about 10x neighbours), corrected to 152. Raw mean 255.9 versus 158.1 after the fix.
- The steel index rose from about 150.8 (first 9 days, corrected) to about 171.4 (last 5 days): 13.7% higher.
- Forecast direction for the tutorial: up (the level shift is recent; say confidence is moderate, since five days is a short history).
- T-035 implementation: the game scores the Outliers step with action remove, so the graded clean table drops the 1520 row (13 rows, mean 158.6) instead of fixing it to 152 (mean 158.1). The finding "level change" is the last 7 days against the 7 days before (171.4 against 151.75, +12.95 percent, band 10..20, up). `test_t035_logic` checks that exactly one value is flagged.

## Day 3: The half-finished Friday (funnel and late-arriving data)

- Case ids: `case_funnel_dropoff`, `case_late_data`. Dataset: web_funnel. Boss question: Which step of the sign-up flow should we fix first?
- Learning goals: step-to-step conversion; compare proportions, not raw counts; check the export time; exclude or flag a partial day.
- Cards: hb_funnel, hb_late_data.

File `web_funnel_day3.csv` (20 rows):

```csv
date,step,users,exported_at
2026-03-02,visit,500,23:59
2026-03-02,signup_start,150,23:59
2026-03-02,signup_done,105,23:59
2026-03-02,first_purchase,21,23:59
2026-03-03,visit,520,23:59
2026-03-03,signup_start,156,23:59
2026-03-03,signup_done,109,23:59
2026-03-03,first_purchase,22,23:59
2026-03-04,visit,480,23:59
2026-03-04,signup_start,144,23:59
2026-03-04,signup_done,101,23:59
2026-03-04,first_purchase,20,23:59
2026-03-05,visit,510,23:59
2026-03-05,signup_start,153,23:59
2026-03-05,signup_done,107,23:59
2026-03-05,first_purchase,21,23:59
2026-03-06,visit,190,10:00
2026-03-06,signup_start,57,10:00
2026-03-06,signup_done,20,10:00
2026-03-06,first_purchase,2,10:00
```

Defects: the last day (2026-03-06) was exported at 10:00, so it is partial; the other days at 23:59.

Expected steps:
1. Inspect the exported_at column; notice 10:00 on the last day.
2. Filter out date 2026-03-06 (or mark partial).
3. Group by step, sum users.
4. Compute step conversion: visit to signup_start, signup_start to signup_done, signup_done to first_purchase.
5. Chart as a sorted bar of step conversion.

Expected findings (complete days 03-02 to 03-05): visit 2010, signup_start 603, signup_done 422, first_purchase 84.
- Step conversion: visit to start 30.0%, start to done 70.0%, done to first purchase 19.9%; overall visit to purchase 4.2%.
- The weakest step after the top of the funnel is signup_done to first_purchase (19.9%). Look at it first.
- With the partial day included the rates become 30.0%, 67.0%, 19.5%, overall 3.9%; the last day alone shows 2 purchases from 190 visits (1.1%), which looks like a collapse but is late data.
- Accept either 'signup_done to first_purchase' as the answer; the first step (visit to signup_start, 30%) is a secondary note.

## Day 4: Too few users to tell (small sample and p-value)

- Case ids: `case_ab_significance`, `case_ab_sample_size`, `case_small_sample`. Dataset: ab_test_log. Boss question: Variant B looks better. Should we roll it out?
- Learning goals: conversion per variant; a visible gap can be luck; read the p-value carefully; say how many users would be needed.
- Cards: hb_ab_test, hb_pvalue, hb_noise_sample, hb_sample_size.

File `ab_test_log_day4.csv` (24 rows):

```csv
user_id,variant,converted,date
u01,A,0,2026-03-02
u02,A,0,2026-03-03
u03,A,1,2026-03-04
u04,A,0,2026-03-05
u05,A,1,2026-03-02
u06,A,0,2026-03-03
u07,A,0,2026-03-04
u08,A,1,2026-03-05
u09,A,0,2026-03-02
u10,A,0,2026-03-03
u11,A,1,2026-03-04
u12,A,0,2026-03-05
u13,B,0,2026-03-02
u14,B,1,2026-03-03
u15,B,1,2026-03-04
u16,B,0,2026-03-05
u17,B,0,2026-03-02
u18,B,1,2026-03-03
u19,B,0,2026-03-04
u20,B,1,2026-03-05
u21,B,1,2026-03-02
u22,B,0,2026-03-03
u23,B,0,2026-03-04
u24,B,1,2026-03-05
```

Defects: none in the rows. The trap is the sample size (12 users per variant).

Expected steps:
1. Group by variant, count users and sum converted.
2. Compute conversion rate per variant.
3. Run the significance check (the tutorial uses an exact test because the counts are tiny).
4. Decide.

Expected findings:
- A: 4 of 12 converted (33.3%). B: 6 of 12 converted (50.0%). Gap: 16.7% points.
- Fisher exact test two-sided p = 0.68. This is far from 0.05: a gap this size is common by luck with 12 users per group. The result is inconclusive, not negative.
- To detect a gap of this size (33% vs 50%) with 80% power at the 5% level you would need roughly 133 users per variant.
- Correct recommendation: do not roll out on this evidence; keep testing. Lower the report confidence.
- Wrong paths: roll out because 50% beats 33%; conclude B does not work.

## Day 5: Winner by group, loser overall (Simpson's paradox)

- Case id: `case_simpson`. Dataset: ab_test_log (aggregated by week and device). Boss question: Which checkout version converts better, A or B?
- Learning goals: overall rate versus rates inside groups; check group mix; compare like with like.
- Cards: hb_simpson, hb_confounder, hb_segmentation.

File `checkout_by_device_day5.csv` (16 rows):

```csv
week,device,variant,visitors,orders
W1,desktop,A,200,40
W1,mobile,A,50,2
W1,desktop,B,50,11
W1,mobile,B,200,10
W2,desktop,A,200,40
W2,mobile,A,50,2
W2,desktop,B,50,11
W2,mobile,B,200,10
W3,desktop,A,200,40
W3,mobile,A,50,2
W3,desktop,B,50,11
W3,mobile,B,200,10
W4,desktop,A,200,40
W4,mobile,A,50,2
W4,desktop,B,50,11
W4,mobile,B,200,10
```

Defects: none in the rows. The trap is the unequal device mix between variants.

Expected steps:
1. Group by variant: sum visitors and orders, compute orders / visitors.
2. Group by variant and device: same.
3. Compare variants within each device.
4. Note the traffic mix (share of mobile visitors per variant).

Expected findings:
- Overall: A 168 orders from 1000 visitors (16.8%); B 84 from 1000 (8.4%). A looks twice as good.
- Desktop: A 20.0%, B 22.0%. Mobile: A 4.0%, B 5.0%. B is better in both groups.
- Mix: A got 80% desktop (800 of 1000), B got 20% desktop (200 of 1000). Desktop converts much better than mobile, so A's overall rate is lifted by its desktop-heavy traffic.
- Like-for-like (same 50/50 mix): A = (20% + 4%) / 2 = 12.0%; B = (22% + 5%) / 2 = 13.5%.
- Correct statement: do not call A the winner on the overall rate; B is better within each device. Also note that traffic was not allocated evenly, so confirm how users were assigned before trusting any comparison.

## Notes for T-035
- Quartile method (fixed in T-035): the engine's `ops.gd` uses linear interpolation (type 7), so day 2 shows Q1 = 150.25, Q3 = 171, fences 119.1 and 202.1. The old median-of-halves numbers (150 / 171 / 118.5 / 202.5) give the same single outlier. The doc was changed, not the engine, because the generator tunes its fences to this method.
- All datasets are tiny on purpose so the player can read every row.
- Day 4 and Day 5 each have two valid report wordings; the grader should accept either as long as it avoids the wrong paths.
