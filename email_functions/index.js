const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const nodemailer = require("nodemailer");
const logger = require("firebase-functions/logger");

// קונפיגורציית SMTP שלך
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true,
  auth: {
    user: "placeme.system@gmail.com",  // המייל החדש
    pass: "gcqfiiftqctfuaat",              // הסיסמה – בלי רווחים!
  },
});


// פונקציה שתפעיל כשמסמך חדש נוסף לאוסף mail
exports.sendEmailOnNewMail = onDocumentCreated("mail/{docId}", async (event) => {
  const mailData = event.data.data();

  if (!mailData  !mailData.to  !mailData.message) {
    logger.error("Missing required mail data");
    return;
  }

  const mailOptions = {
from: '"PlaceMe App" placeme.system@gmail.com',
    to: mailData.to,                                // הנמען
    subject: mailData.message.subject  "No subject",
    text: mailData.message.text  "",
    html: mailData.message.html || undefined,       // אופציונלי, אם יש HTML
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    logger.info(Email sent to ${mailData.to}: ${info.messageId});
  } catch (error) {
    logger.error("Error sending email:", error);
  }
});