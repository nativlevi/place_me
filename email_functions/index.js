const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const nodemailer = require("nodemailer");
const logger = require("firebase-functions/logger");

// קונפיגורציית SMTP שלך
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",      // או שרת SMTP אחר
  port: 465,
  secure: true,                // true for 465, false for other ports
  auth: {
    user: "nativl12345@gmail.com",      // המייל שלך
    pass: "AJHJUXEATOHFDNJN",            // סיסמת האפליקציה (App Password) או סיסמה רגילה
  },
});

// פונקציה שתפעיל כשמסמך חדש נוסף לאוסף mail
exports.sendEmailOnNewMail = onDocumentCreated("mail/{docId}", async (event) => {
  const mailData = event.data.data();

  if (!mailData || !mailData.to || !mailData.message) {
    logger.error("Missing required mail data");
    return;
  }

  const mailOptions = {
    from: '"PlaceMe App" <nativl12345@gmail.com>', // השולח
    to: mailData.to,                                // הנמען
    subject: mailData.message.subject || "No subject",
    text: mailData.message.text || "",
    html: mailData.message.html || undefined,       // אופציונלי, אם יש HTML
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    logger.info(`Email sent to ${mailData.to}: ${info.messageId}`);
  } catch (error) {
    logger.error("Error sending email:", error);
  }
});
