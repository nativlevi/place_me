import pandas as pd
import matplotlib.pyplot as plt

def ensure_bool(series):
    if series.dtype == object:
        return series.astype(str).str.lower().map({'true': True, 'false': False})
    return series

# --- תיקון עיבוד NaN כ-True לאספקטים ---
def safe_bool(val):
    if pd.isna(val):
        return True
    if isinstance(val, bool):
        return val
    return str(val).lower() == "true"

# קרא את הקובץ שנוצר בניתוח
df = pd.read_csv("seating_analysis_all_auto_events.csv")

# המרת הערכים לעמודות בוליאניות (למניעת שגיאות)
df['got_wanted_neighbor'] = ensure_bool(df['got_wanted_neighbor'])
df['avoided_unwanted'] = ensure_bool(df['avoided_unwanted'])
df['features_matched'] = ensure_bool(df['features_matched'])

# תמיד True ירוק ו-False אדום (שים לב לסדר values במשתנה counts)
def plot_bool_pie(series, title, labels):
    counts = series.value_counts().reindex([True, False], fill_value=0)
    colors = ['#90ee90', '#f08080']  # ירוק ל-True, אדום ל-False
    fig, ax = plt.subplots()
    ax.pie(
        counts,
        autopct='%1.0f%%',
        labels=labels,
        colors=colors,
        startangle=90,
        counterclock=False
    )
    ax.set_title(title)
    plt.ylabel("")
    plt.show()

# 1. גרף שכנות רצויה
plot_bool_pie(
    df['got_wanted_neighbor'],
    "שכנות רצויה",
    ["קיבל שכן שרצה", "לא קיבל שכן שרצה"]
)

# 2. גרף הימנעות משכנות לא רצויה
plot_bool_pie(
    df['avoided_unwanted'],
    "הימנעות משכנות לא רצויה",
    ["לא ישב ליד מישהו שניסה להימנע", "ישב ליד מישהו שניסה להימנע"]
)

# 3. גרף התאמת מאפיינים
plot_bool_pie(
    df['features_matched'],
    "התאמת מאפיינים",
    ["קיבל לפחות אחד", "לא קיבל אף מאפיין שרצה"]
)

# --- גרף מסכם רמות שביעות רצון ---
# חישוב רמת שביעות רצון לכל משתתף (תמיד NaN -> True)
satisfaction = []
for i, row in df.iterrows():
    num_true = int(safe_bool(row['got_wanted_neighbor'])) + \
               int(safe_bool(row['avoided_unwanted'])) + \
               int(safe_bool(row['features_matched']))
    if num_true == 3:
        satisfaction.append('ממש מרוצה')
    elif num_true > 0:
        satisfaction.append('חצי מרוצה')
    else:
        satisfaction.append('לא מרוצה')

df['satisfaction'] = satisfaction

# גרף עוגה - שביעות רצון כוללת
counts = df['satisfaction'].value_counts().reindex(['ממש מרוצה', 'חצי מרוצה', 'לא מרוצה'], fill_value=0)
colors = ['#40c057', '#ffd43b', '#fa5252']  # ירוק=מרוצה, צהוב=חצי, אדום=לא מרוצה
fig, ax = plt.subplots()
ax.pie(
    counts,
    autopct='%1.0f%%',
    labels=counts.index,
    colors=colors,
    startangle=90,
    counterclock=False
)
ax.set_title("רמת שביעות רצון כוללת")
plt.ylabel("")
plt.show()
