import os
from dotenv import load_dotenv
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup, WebAppInfo
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes

load_dotenv()
TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
GAME_URL = "https://sinxity.github.io/block-craft/BlockCraft.html"

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    keyboard = [[
        InlineKeyboardButton("🎮 Играть", web_app=WebAppInfo(url=GAME_URL))
    ]]
    await update.message.reply_text(
        "Добро пожаловать в Block Craft! 🧱\nНажми кнопку чтобы начать играть:",
        reply_markup=InlineKeyboardMarkup(keyboard)
    )

if __name__ == "__main__":
    app = ApplicationBuilder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    print("Bot started!")
    app.run_polling()
