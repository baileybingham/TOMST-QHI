# Yearly Raw Data Summaries

## 2022 TOMST Data
**`n = 40` TOMST downloaded**

* In 2022, all TOMST loggers were deployed on QHI for the first time between July 18th and July 27th (see `Allyears_TOMST_Fieldnotes.csv` for details).
* **Data Cleaning:** Any dates before their respective deployment dates must be removed, as TOMST loggers begin recording data from the time they are manufactured.
* Data from all 40 TOMST loggers were successfully downloaded in early August 2022.

---

## 2023 TOMST Data
**`n = 39` TOMST downloaded**

* From early August 2022, the TOMST loggers were left to continue monitoring until their next download in late June 2023.
* **Lost/Dead Loggers:** By late June 2023, `TOMST_02` had died and its data was unrecoverable (`n = 39` downloaded). During a second download in early August 2023, `TOMST_11` was not recovered, so its data only extends until the late June 2023 download.
* Neither `TOMST_02` nor `TOMST_11` was replaced in 2023.

---

## 2024 TOMST Data
**`n = 37` TOMST downloaded**

* From early August 2023, the loggers continued monitoring until the next download in early August 2024.
* **Lost/Dead Loggers:** By August 2024, `TOMST_05` was lost and unrecoverable (in addition to `TOMST_02` and `TOMST_11` from 2023, which remained unreplaced).
* > **Important — Site Relocation (`TOMST_05` & `TOMST_34`):** Because `TOMST_05` is a high-priority location (ITEX plot and Phenocam), the hardware from nearby `TOMST_34` was moved to the `TOMST_05` site. Long-term monitoring at the `TOMST_34` site was discontinued moving forward.
* > **Important — Sensor Damage (`TOMST_14`):** `TOMST_14` was downloaded in 2024 but was not redeployed due to damage. All data after **June 13, 2024** for `TOMST_14` reads as `-81.12` and must be converted to `NA`.

---

## 2025 TOMST Data
**`n = 33` TOMST downloaded**

* **Missing/Discontinued Loggers:** `TOMST_02`, `TOMST_11`, `TOMST_14`, and `TOMST_34` were not downloaded in 2025 as they were not redeployed after damage, loss, or discontinuation in previous years. Additionally, `TOMST_08`, `TOMST_27`, and `TOMST_29` were lost/not recovered this year.
* > **Important — Data Merging (`TOMST_05`):** All 2025 download data from `TOMST_05` prior to its relocation date (~August 11, 2024) actually belongs to `old_TOMST_34`. This pre-move data must be separated from `TOMST_05` and merged with the historical `TOMST_34` dataset.
* > **Note on Redeployments:** Some TOMST loggers were replaced during the 2025 field season, but serial numbers and sites were not properly tracked. These will be reconciled in future years when the new serial numbers are downloaded at their respective sites.

---

## 2026 TOMST Data
**`n = 36` TOMST downloaded (`32` usable)**

* **Unlabeled Downloads:** Four of the 36 downloads have new serial numbers that are not yet associated with known sites due to incomplete 2025 field notes. Site associations will be confirmed during the 2027 field season.
* **Confirmed Redeployments (`TOMST_02` & `TOMST_27`):** Both sites were redeployed with new serial numbers in August 2025 and downloaded in 2026.
  * **Data Cleaning:** Remove all dates prior to **August 15, 2025** for these loggers, as they were not yet deployed.
* **Unrecovered / Missing Downloads:** 
  * `TOMST_04`, `TOMST_08`, `TOMST_11`, `TOMST_14`, `TOMST_28`, and `TOMST_29` were not downloaded in 2026 (they may or may not have been redeployed in 2025).
  * `TOMST_07` was also not recovered in 2026.
  * > **Note:** Four of these missing sites are likely accounted for by the four unlabeled downloads with new serial numbers mentioned above.
