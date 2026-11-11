# Content bible: Data Corp v2

Version 0.2, 2026-11-11. Owner: Claude. Design source: `docs/GDD-v2-concept.md`. Machine-readable data: `data/news.json` (123 news templates, 16 sources). **All names, organizations, tickers and figures in the game are fictional.** No real company names, brands, characters or events are used.

Language note: the v2 in-game text (`data/strings_v2.json`) is already English. Fictional proper names and data ids (for example `lai_suat`, `chinh_thuc`) are kept as they appear in the data files. The v1 dashboard strings (`data/strings.json`, `data/events.json`) are still Vietnamese; see `docs/GITHUB-READINESS.md`.

## 1. The world

The **Republic of Tan Lac** (fictional, "Cong hoa Tan Lac"), currency the **lac dong** ("dong lac"). The world is in a **generic credit crisis**: interest rates rise, credit tightens, the lac dong loses value, purchasing power falls. It is not tied to any real country, year or event. The main stock index is **TLX-30**. Two illustrative tickers: **LCD** (a small distribution company) and **BMT** (a materials company). Both are fictional.

## 2. The company

**Luc Chau Distribution Company** (fictional): imports and distributes household goods (plastic items, metal tools) to retail agents. Small to medium size, borrows from banks to buy stock, sells to agents on credit.

Meaning of the metrics in the game:

| Metric (already in the simulation) | In the Luc Chau setting |
|---|---|
| Users | Active agents |
| Retention | Share of agents kept each week |
| Conversion | Share of orders closed |
| CAC | Cost of acquiring one more agent |
| ARPU | Average revenue per agent per week |
| LTV/CAC | Value of an agent compared with the cost of acquiring them |
| Data Integrity | Cleanliness of internal data (spreadsheets, weekly reports) |
| Cash | The company's cash on hand |

The company is sensitive to: **interest rate** (borrowing cost), **exchange rate** (imports get more expensive), **raw-material price** (cost of goods), **purchasing power** (agent demand), **credit** (ability to borrow more), and the **stock market** only as a sentiment indicator (the company is not listed).

## 3. Characters

| Role | Name | Short personality |
|---|---|---|
| Boss, Chief Financial Officer | **Ms. Hanh** | Direct, few words, hates being handed numbers without evidence; rewards people who state how sure they are |
| Chief Accountant | **Mr. Khoi** | Careful, doubts the numbers, reminds the player to reconcile with the books |
| Intern | **Mai** | Enthusiastic, reads rumors on social media and retells them (a source of false and partly true news) |
| Warehouse worker, security guard | **Uncle Tu** | Talks about everyday things, sometimes warns of internal problems in advance |
| Player | **You** (nameable) | Analyst, starts at the Intern rank |

The names are generic and not aimed at any real person. If one coincides with a real person by accident, change it.

## 4. News sources (16 sources, see `data/news.json`)

| Type | Source (fictional) | Reliability | Delay |
|---|---|---:|---:|
| Official | Tan Lac Statistics Office | 0.95 | 2 days |
| Official | Tan Lac Central Bank | 0.97 | 0 |
| Official | Tan Lac Stock Exchange | 0.97 | 0 |
| Press | Tan Lac Daily | 0.82 | 1 day |
| Press | Morning Finance Bulletin | 0.80 | 0 |
| Press | Dai Duong News Agency | 0.85 | 1 day |
| Social media | Anonymous Investors Forum | 0.40 | 0 |
| Social media | "Tam Chuyen" (Gossip) Network | 0.45 | 0 |
| Official | Tan Lac Trade Register | 0.95 | 2 days |
| Official | Tan Lac Settlement Office | 0.97 | 0 |
| Official | Tan Lac Market Registry | 0.97 | 0 |
| Press | Harbor Ledger | 0.82 | 1 day |
| Press | Courtyard Dispatch | 0.80 | 0 |
| Press | Canal Review | 0.85 | 1 day |
| Internal | Internal tip (anonymous) | 0.35 | 0 |
| Internal | Colleague at the company | 0.60 | 0 |

Reliability is a reference probability used when generating false news; **the player does not see this number**. The player only sees the source type (a chip) and must learn through experience, together with the verification tools.

### Headline style

- English only, at most 90 characters, with no manual line breaks; verify two-line fit in the existing news cards during layout review.
- Official sources use dry notices and defined reporting periods. Press sources describe business effects with measured language.
- Social sources sound conversational and rumor-like, without emojis. Insiders speak quietly from a limited vantage point.
- Vary framing and vocabulary while keeping the direction, time period, event and magnitude implied by the template's fields intact.
- Keep `{pct}` only where the template supplies `magnitude_pct`. Never expose hidden truth or kind labels in a headline.
- Use original fictional names and tickers. Avoid real institutions, investment instructions, and claims of guaranteed returns.

The six additional sources are peers of the existing official and press sources, with matching reliability and delay. The averages of both fields remain unchanged in every tier. Social and insider voices remain represented by their existing sources.

The 41 original templates remain unchanged. Two new headlines per original preserve the topic x kind x source-tier distribution exactly (123 total). Source reliability is still hidden from the player.

## 5. The "kind" and "truth" labels of news

| kind | truth | Meaning |
|---|---|---|
| signal | dung (true) | Reflects the real state or shock |
| trap | sai (false) | Wrong or exaggerated, easily misleading |
| partial | mot_phan (partly true) | Partly right (right direction but wrong magnitude, or missing context) |
| stale | cu (outdated) | True but old compared with the current situation |
| noise | khong_lien_quan (unrelated) | Not relevant to the company |

Every run must contain all five kinds. Suggested ratios when generating daily news: signal about 45%, trap 17%, partial 10%, stale 10%, noise 15% (Codex tunes them by simulation, staying within about half of each value).

## 6. World state variables (hidden)

`lai_suat` (interest rate), `ty_gia` (exchange rate), `nguyen_lieu` (raw material), `suc_mua` (purchasing power), `chung_khoan` (stock market), `tin_dung` (credit). Each variable has a value per day (up, down, flat, with a magnitude). A news item with `link: "state:<variable>"` reflects that variable. The company is affected through the existing simulation (for example a rising interest rate raises fixed costs, a rising exchange rate raises cost of goods, falling purchasing power lowers Conversion and Retention). The exact coefficients are set by spec T-018.

## 7. Shocks: mapping of the 8 existing events

| Event (existing id) | Symptom on the dashboard | Real cause (Luc Chau setting) | Hint news (id in news.json) | Remedy (existing card) |
|---|---|---|---|---|
| `app_bug` | Retention drops among new agents | The order portal fails on first open | `noi_bo_cong_dat_hang_loi` | Onboarding Redesign |
| `competitor_discount` | Retention drops among price-sensitive agents | A competitor imports cheaper (exchange rate) and cuts prices | `suc_mua_doi_thu_giam_gia`, `suc_mua_giam_gia_quang_cao` | Loyalty, Discount |
| `logging_error` | Dashboard shows Retention dropping | The weekly report has duplicate rows; the real number is unchanged | `noi_bo_bang_so_trung` | Clean Data |
| `checkout_outage` | Conversion drops | The payment partner has an incident | `tin_dung_bao_tri_thanh_toan` | Fix Checkout Bug |
| `server_outage` | Users and Conversion drop | The warehouse system is overloaded at peak hours | `noi_bo_kho_cham` | Support Automation |
| `trend_shift` | CAC rises | Purchasing power shifts to essential goods | `suc_mua_thiet_yeu` | SEO Content |
| `bad_traffic` | Retention drops after a campaign | The advertising campaign targeted the wrong audience | `noi_bo_quang_cao_it_don` | Onboarding Redesign |
| `price_fatigue` | Conversion drops | Raw-material prices rise, pushing selling prices up, and customers tire of it | `suc_mua_khach_phan_nan_gia`, `nguyen_lieu_nhua_thep_tang` | Discount, Loyalty |

A post-demo expansion may add purely macro shocks (for example a sudden interest-rate rise), but the demo uses only the 8 shocks above so the core simulation does not change.

## 8. Analysis tools (renamed from analysis cards)

| Tool id | Existing card | Display name | Effect |
|---|---|---|---|
| `truy_van_lich_su` | SQL Deep-Dive | Query historical data | View past price and metric series, reveals internal causes |
| `kiem_dinh_gia_thuyet` | A/B Test | Hypothesis test | Reduces forecast noise, reveals trend and price causes |
| `doi_chieu_nguon` | Funnel Report | Cross-check sources | Compares two sources and says whether an item is confirmed, refuted, or lacks evidence |
| `lam_sach_du_lieu` | Clean Data | Clean data | Raises the cleanliness of internal data, filters duplicate rows |

The recommended actions for the boss reuse the remaining 8 cards, renamed to fit the context: Fix Checkout Bug becomes "Tighten receivables collection through the payment gateway", Onboarding Redesign becomes "Improve the ordering process for new agents", Ads Campaign becomes "Marketing spend to find agents", Influencer Campaign becomes "Partner with a large distribution channel", Loyalty Program becomes "Agent retention program", SEO Content becomes "Online retail content and channels", Support Automation becomes "Automate warehouse and customer care", Discount becomes "Temporary promotion". The real names are used in `data/strings.json` (Codex).

## 9. The boss's question of the day (sample for the 10-day demo)

1. Will the imported raw-material price this week rise, fall, or stay flat?
2. Should we order an extra large batch before the exchange rate rises further?
3. How will the business loan interest rate change next week?
4. Will household-goods purchasing power recover this quarter or keep falling?
5. Is the competitor's price cut worth worrying about, or just advertising?
6. Is the partner bank trustworthy enough to put a large payment through it?
7. Should we use the reserve fund for a sales campaign?
8. Are the weekly report figures reliable enough to present to the board?
9. Does the rumor that a bank is about to collapse require immediate action?
10. Looking back at the whole stretch: should the company hold cash or invest in inventory?

The expanded bank contains 20 questions: three per hidden state variable, plus the existing rival-discount and report-integrity questions. Each question has a relevant file mapping in `datasets.json` under `relevance.map`; questions about the stock index concern sentiment rather than direct company returns. New state questions use the existing current-state answer rule and frame pricing, hiring, inventory, loans, marketing spend and expansion decisions without prescribing an action.

Every question has a predetermined answer according to the run's world scenario (Codex generates it from the seed).

## 10. Tone and sample dialogue

Short, everyday, slightly wry, not intimidating, not judgmental.

- Ms. Hanh on a good report: "Good. Keep stating your certainty like that next time."
- When wrong but with low confidence: "Wrong, but you warned me you were not sure. Noted."
- When wrong with high confidence: "You said you were certain. Now the company is paying for it."
- Warning: "This is the second warning. I need to see evidence in the report, not feelings."
- Promotion: "From next week you are an Analyst. Do not make me regret it."
- Dismissal: "I am sorry, but the company cannot stand if this continues."
- Mr. Khoi: "Does this number match the books yet? I see two duplicate rows."
- Mai: "On Tam Chuyen they say plastic prices are about to double!"
- Uncle Tu: "The warehouse is very slow today, the computer keeps freezing at receiving time."

## 11. Prohibited

- Names of real companies, banks, agencies, newspapers, famous people, or real economic events.
- Real market figures. Every number is produced by the simulation.
- Real investment advice, real trading instructions, or real money in the game.
- Political, religious, inciting or discriminatory content.
- Messages implying that social-media rumors are always false: there is true news on every type of source, so the player must verify instead of relying on a hard rule.

## 12. Mandatory disclaimer in the game and on the landing page

"Data and names in the game are fictional and generated by simulation. They are not real market data and not investment advice. Part of the content and code was created with AI assistance."
