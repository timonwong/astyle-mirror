/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *   ASLocalizer.cpp
 *
 *   Copyright (C) 2006-2010 by Jim Pattee <jimp03@email.com>
 *   Copyright (C) 1998-2002 by Tal Davidson
 *   <http://www.gnu.org/licenses/lgpl-3.0.html>
 *
 *   This file is a part of Artistic Style - an indentation and
 *   reformatting tool for C, C++, C# and Java source files.
 *   <http://astyle.sourceforge.net>
 *
 *   Artistic Style is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Lesser General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   Artistic Style is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public License
 *   along with Artistic Style.  If not, see <http://www.gnu.org/licenses/>.
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 */

//----------------------------------------------------------------------------
// headers
//----------------------------------------------------------------------------

#ifdef _WIN32
#include <windows.h>
#endif

#ifdef __DMC__
#include <locale.h>
#endif

#include <cstdio>
#include <iostream>
#include <stdlib.h>
#include <typeinfo>

#include "astyle_main.h"
#include "ASLocalizer.h"

namespace astyle
{

#ifndef ASTYLE_LIB

//----------------------------------------------------------------------------
// ASLocalizer class methods.
//----------------------------------------------------------------------------

ASLocalizer::ASLocalizer()
// Set the locale information.
{
	// set language default values to english (ascii)
	// this will be used if a locale or a language cannot be found
	m_localeName = "UNKNOWN";
	m_langID = "en";
	m_lcid = 0;
	m_subLangID.clear();
	m_translation = NULL;

	// Not all compilers support the C++ function locale::global(locale(""));
	// For testing on Windows change the "Region and Language" settings or use AppLocale.
	// For testing on Linux change the LANG environment variable: LANG=fr_FR.UTF-8.
	// setlocale() will use the LANG environment valiable on Linux.

	char* localeName = setlocale(LC_ALL, "");
	if (localeName == NULL)		// use the english (ascii) defaults
	{
		setTranslationClass();
		return;
	}
	// set the class variables
#ifdef _WIN32
	size_t lcid = GetUserDefaultLCID();
	setLanguageFromLCID(lcid);
#else
	setLanguageFromName(localeName);
#endif
}

ASLocalizer::~ASLocalizer()
// Delete dynamically allocated memory.
{
	delete m_translation;
}

#ifdef _WIN32

#ifdef __DMC__
// digital mars doesn't have these
const size_t SUBLANG_CHINESE_MACAU = 5;
const size_t LANG_HINDI = 57;
#endif

struct WinLangCode
{
	size_t winLang;
	char canonicalLang[3];
};

static WinLangCode wlc[] =
// primary language identifier http://msdn.microsoft.com/en-us/library/aa912554.aspx
// sublanguage identifier http://msdn.microsoft.com/en-us/library/aa913256.aspx
// language ID http://msdn.microsoft.com/en-us/library/ee797784%28v=cs.20%29.aspx
{
	{ LANG_CHINESE,    "zh" },
	{ LANG_DUTCH,      "nl" },
	{ LANG_ENGLISH,    "en" },
	{ LANG_FINNISH,    "fi" },
	{ LANG_FRENCH,     "fr" },
	{ LANG_GERMAN,     "de" },
	{ LANG_HINDI,      "hi" },
	{ LANG_ITALIAN,    "it" },
	{ LANG_JAPANESE,   "ja" },
	{ LANG_KOREAN,     "ko" },
	{ LANG_POLISH,     "pl" },
	{ LANG_PORTUGUESE, "pt" },
	{ LANG_RUSSIAN,    "ru" },
	{ LANG_SPANISH,    "es" },
	{ LANG_SWEDISH,    "sv" },
	{ LANG_UKRAINIAN,  "uk" },
};

void ASLocalizer::setLanguageFromLCID(size_t lcid)
// Windows get the language to use from the user locale.
// NOTE: GetUserDefaultLocaleName() gets nearly the same name as Linux.
//       But it needs Windows Vista or higher.
//       Same with LCIDToLocaleName().
{
	m_lcid = lcid;
	m_langID == "en";	// default to english

	size_t lang = PRIMARYLANGID(LANGIDFROMLCID(m_lcid));
	size_t sublang = SUBLANGID(LANGIDFROMLCID(m_lcid));
	// find language in the wlc table
	size_t count = sizeof(wlc)/sizeof(wlc[0]);
	for (size_t i = 0; i < count; i++ )
	{
		if (wlc[i].winLang == lang)
		{
			m_langID = wlc[i].canonicalLang;
			break;
		}
	}
	if (m_langID == "zh")
	{
		if (sublang == SUBLANG_CHINESE_SIMPLIFIED || sublang == SUBLANG_CHINESE_SINGAPORE)
			m_subLangID = "CHS";
		else
			m_subLangID = "CHT";	// default
	}
	setTranslationClass();
}

#endif	// _win32

string ASLocalizer::getLanguageID() const
// Returns the language ID in m_langID.
{
	return m_langID;
}

const Translation* ASLocalizer::getTranslationClass() const
// Returns the name of the translation class in m_translation.
{
	assert(m_translation);
	return m_translation;
}

void ASLocalizer::setLanguageFromName(const char* langID)
// Linux set the language to use from the langID.
//
// the language string has the following form
//
//      lang[_LANG][.encoding][@modifier]
//
// (see environ(5) in the Open Unix specification)
//
// where lang is the primary language, LANG is a sublang/territory,
// encoding is the charset to use and modifier "allows the user to select
// a specific instance of localization data within a single category"
//
// for example, the following strings are valid:
//      fr
//      fr_FR
//      de_DE.iso88591
//      de_DE@euro
//      de_DE.iso88591@euro
{
	// the constants describing the format of lang_LANG locale string
	static const size_t LEN_LANG = 2;
	static const size_t LEN_SUBLANG = 2;

	m_lcid = 0;
	string langStr = langID;
	m_langID = langStr.substr(0, LEN_LANG);

	// need the sublang for chinese
	if (m_langID == "zh" && langStr[LEN_LANG] == '_')
	{
		string subLang = langStr.substr(LEN_LANG + 1, LEN_SUBLANG);
		if (subLang == "CN" || subLang == "SG")
			m_subLangID = "CHS";
		else
			m_subLangID = "CHT";	// default
	}
	setTranslationClass();
}

const char* ASLocalizer::settext(const char* textIn) const
// Call the settext class and return the value.
{
	assert(m_translation);
	const string stringIn = textIn;
	return m_translation->translate(stringIn).c_str();
}

void ASLocalizer::setTranslationClass()
// Return the required translation class.
// Sets the class variable m_translation from the value of m_langID.
// Get the language ID at http://msdn.microsoft.com/en-us/library/ee797784%28v=cs.20%29.aspx
{
	assert(m_langID.length());
	if (m_langID == "zh" && m_subLangID == "CHS")
		m_translation = new ChineseSimplified;
	else if (m_langID == "zh" && m_subLangID == "CHT")
		m_translation = new ChineseTraditional;
	else if (m_langID == "en")
		m_translation =  new English;
	else if (m_langID == "es")
		m_translation =  new Spanish;
	else if (m_langID == "fr")
		m_translation = new French;
	else if (m_langID == "de")
		m_translation = new German;
	else if (m_langID == "hi")
		m_translation = new Hindi;
	else	// default
		m_translation = new English;
}

//----------------------------------------------------------------------------
// Translation base class methods.
//----------------------------------------------------------------------------

void Translation::addPair(const string& english, const wstring& translated)
// Add a string pair to the translation vector.
{
	pair<string, wstring> entry (english, translated);
	m_translation.push_back(entry);
}

string Translation::convertToMultiByte(const wstring& wideStr) const
// Convert wchar_t to a multibyte string using the currently assigned locale.
// The converted string is in m_mbTranslation.
{
	// get length of the output excluding the NULL and validate the parameters
	size_t mbLen = wcstombs(NULL, wideStr.c_str(), 0);
	if (mbLen == string::npos)
		systemAbort("Bad char in wide character string");
	// convert the characters
	char* mbStr = new(nothrow) char[mbLen+1];
	if (mbStr == NULL)
		systemAbort("Bad memory alloc for multi-byte string");
	wcstombs(mbStr, wideStr.c_str(), mbLen+1);
	// return the string
	string mbTranslation = mbStr;
	delete [] mbStr;
	return mbTranslation;
}

size_t Translation::getTranslationVectorSize() const
// Return the translation vector size.  Used for testing.
{
	return m_translation.size();
}

bool Translation::getWideTranslation(const string& stringIn, wstring& wideOut) const
// Get the wide translation string. Used for testing.
{
	size_t i;
	for (i = 0; i < m_translation.size(); i++)
	{
		if (m_translation[i].first == stringIn)
		{
			wideOut = m_translation[i].second;
			return true;
		}
	}
	// not found
	wideOut = L"";
	return false;
}

string& Translation::translate(const string& stringIn) const
// Translate a string.
// Return a static string instead of a member variable so the method can have a "const" designation.
// This allows "settext" to be called from a "const" method.
{
	static string mbTranslation;
	mbTranslation.clear();
	for (size_t i = 0; i < m_translation.size(); i++)
	{
		if (m_translation[i].first == stringIn)
		{
			mbTranslation = convertToMultiByte(m_translation[i].second);
			break;
		}
	}
	// not found, return english
	if (mbTranslation.empty())
		mbTranslation = stringIn;
	return mbTranslation;
}

void Translation::systemAbort(const string& message) const
{
	cerr << message << endl;
	cerr << "\nArtistic Style has terminated!" << endl;
	exit(EXIT_FAILURE);
}

//----------------------------------------------------------------------------
// Translation class methods.
// These classes have only a constructor which builds the language vector.
//----------------------------------------------------------------------------

ChineseSimplified::ChineseSimplified()
{
	addPair("formatted %s\n", L"格式化 %s\n");		// should align with unchanged
	addPair("unchanged %s\n", L"不变   %s\n");		// should align with formatted
	addPair("directory %s\n", L"目录 %s\n");
	addPair(" %s formatted;  %s unchanged;  ", L" %s 格式化;  %s 不变;  ");
	addPair(" seconds;  ", L" 秒;  ");
	addPair("%d min %d sec;  ", L"%d 分钟 %d 秒;  ");
	addPair("%s lines\n", L"%s 线\n");
	addPair("exclude %s\n", L"排除 %s\n");
	addPair("Using default options file %s\n", L"使用默认选项文件 %s\n");
	addPair("Invalid option file options:", L"无效的选项文件选项：");
	addPair("Invalid command line options:", L"无效的命令行选项：");
	addPair("For help on options type 'astyle -h'", L"上选项的帮助下键入 'astyle -h'");
	addPair("Cannot open options file", L"无法打开选项文件");
	addPair("Cannot open input file", L"无法打开输入文件");
	addPair("Cannot open directory", L"无法打开目录");
	addPair("Cannot process the input stream", L"无法处理的输入流");
	addPair("\nArtistic Style has terminated!", L"\nArtistic Style 已经终止！");
}

ChineseTraditional::ChineseTraditional()
{
	addPair("formatted %s\n", L"格式化 %s\n");		// should align with unchanged
	addPair("unchanged %s\n", L"不變   %s\n");		// should align with formatted
	addPair("directory %s\n", L"目錄 %s\n");
	addPair(" %s formatted;  %s unchanged;  ", L" %s 格式化;  %s 不變;  ");
	addPair(" seconds;  ", L" 秒;  ");
	addPair("%d min %d sec;  ", L"%d 分鐘 %d 秒;  ");
	addPair("%s lines\n", L"%s 線\n");
	addPair("exclude %s\n", L"排除 %s\n");
	addPair("Using default options file %s\n", L"使用默認選項文件 %s\n");
	addPair("Invalid option file options:", L"無效的選項文件選項：");
	addPair("Invalid command line options:", L"無效的命令行選項：");
	addPair("For help on options type 'astyle -h'", L"如需幫助選項鍵入 'astyle -h'");
	addPair("Cannot open options file", L"無法打開選項文件");
	addPair("Cannot open input file", L"無法打開輸入文件");
	addPair("Cannot open directory", L"無法打開目錄");
	addPair("Cannot process the input stream", L"無法處理的輸入流");
	addPair("\nArtistic Style has terminated!", L"\nArtistic Style 已經終止！");
}

English::English()
// this class is NOT translated
{}

French::French()
// build the translation vector in the Translation base class
{
	addPair("formatted %s\n", L"formaté   %s\n");	// should align with unchanged
	addPair("unchanged %s\n", L"inchangée %s\n");	// should align with formatted
	addPair("directory %s\n", L"répertoire %s\n");
	addPair(" %s formatted;  %s unchanged;  ", L" %s formaté;  %s inchangée;  ");
	addPair(" seconds;  ", L" seconde;  ");
	addPair("%d min %d sec;  ", L"%d min %d sec;  ");
	addPair("%s lines\n", L"%s lignes\n");
	addPair("exclude %s\n", L"exclure %s\n");
	addPair("Using default options file %s\n", L"Options par défaut utilisation du fichier %s\n");
	addPair("Invalid option file options:", L"Options Blancs option du fichier:");
	addPair("Invalid command line options:", L"Blancs options ligne de commande:");
	addPair("For help on options type 'astyle -h'", L"Pour de l'aide sur les options tapez 'astyle -h'");
	addPair("Cannot open options file", L"Impossible d'ouvrir le fichier d'options");
	addPair("Cannot open input file", L"Impossible d'ouvrir le fichier d'entrée");
	addPair("Cannot open directory", L"Impossible d'ouvrir le répertoire");
	addPair("Cannot process the input stream", L"Impossible de traiter le flux d'entrée");
	addPair("\nArtistic Style has terminated!", L"\nArtistic Style a mis fin!");
}

German::German()
// build the translation vector in the Translation base class
{
	addPair("formatted %s\n", L"formatiert  %s\n");	// should align with unchanged
	addPair("unchanged %s\n", L"unverändert %s\n");	// should align with formatted
	addPair("directory %s\n", L"verzeichnis %s\n");
	addPair(" %s formatted;  %s unchanged;  ", L" %s formatiert;  %s unverändert;  ");
	addPair(" seconds;  ", L" sekunden;  ");
	addPair("%d min %d sec;  ", L"%d min %d sek;  ");
	addPair("%s lines\n", L"%s linien\n");
	addPair("exclude %s\n", L"ausschließen %s\n");
	addPair("Using default options file %s\n", L"Mit standard-optionen datei %s\n");
	addPair("Invalid option file options:", L"Ungültige Option Datei Optionen:");
	addPair("Invalid command line options:", L"Ungültige Kommandozeilen-Optionen:");
	addPair("For help on options type 'astyle -h'", L"Für Hilfe zu den Optionen geben Sie 'astyle -h'");
	addPair("Cannot open options file", L"Kann nicht geöffnet werden Optionsdatei");
	addPair("Cannot open input file", L"Kann Eingabedatei nicht öffnen");
	addPair("Cannot open directory", L"Kann nicht geöffnet werden direkt");
	addPair("Cannot process the input stream", L"Kann nicht verarbeiten input stream");
	addPair("\nArtistic Style has terminated!", L"\nArtistic Style ist beendet!");
}

Hindi::Hindi()
// build the translation vector in the Translation base class
{
	addPair("formatted %s\n", L"स्वरूपित किया %s\n");	// should align with unchanged
	addPair("unchanged %s\n", L"अपरिवर्तित    %s\n");	// should align with formatted
	addPair("directory %s\n", L"निर्देशिका %s\n");
	addPair(" %s formatted;  %s unchanged;  ", L" %s स्वरूपित किया;  %s अपरिवर्तित;  ");
	addPair(" seconds;  ", L" सेकंड;  ");
	addPair("%d min %d sec;  ", L"%d मिनट %d सेकंड;  ");
	addPair("%s lines\n", L"%s लाइनों\n");
	addPair("exclude %s\n", L"निकालना %s\n");
	addPair("Using default options file %s\n", L"डिफ़ॉल्ट विकल्प का उपयोग कर फ़ाइल %s\n");
	addPair("Invalid option file options:", L"अवैध विकल्प फ़ाइल विकल्प हैं:");
	addPair("Invalid command line options:", L"कमांड लाइन विकल्प अवैध:");
	addPair("For help on options type 'astyle -h'", L"विकल्पों पर मदद के लिए प्रकार 'astyle -h'");
	addPair("Cannot open options file", L"विकल्प फ़ाइल नहीं खोल सकता है");
	addPair("Cannot open input file", L"इनपुट फ़ाइल नहीं खोल सकता");
	addPair("Cannot open directory", L"निर्देशिका नहीं खोल सकता");
	addPair("Cannot process the input stream", L"इनपुट स्ट्रीम प्रक्रिया नहीं कर सकते");
	addPair("\nArtistic Style has terminated!", L"\nArtistic Style समाप्त किया है!");
}

Spanish::Spanish()
// build the translation vector in the Translation base class
{
	addPair("formatted %s\n", L"formato    %s\n");	// should align with unchanged
	addPair("unchanged %s\n", L"inalterado %s\n");	// should align with formatted
	addPair("directory %s\n", L"directorio %s\n");
	addPair(" %s formatted;  %s unchanged;  ", L" %s formato;  %s inalterado;  ");
	addPair(" seconds;  ", L" segundo;  ");
	addPair("%d min %d sec;  ", L"%d min %d seg;  ");
	addPair("%s lines\n", L"%s líneas\n");
	addPair("exclude %s\n", L"excluir %s\n");
	addPair("Using default options file %s\n", L"Uso de las opciones por defecto del archivo %s\n");
	addPair("Invalid option file options:", L"Opción no válida opciones de archivo:");
	addPair("Invalid command line options:", L"No válido opciones de línea de comando:");
	addPair("For help on options type 'astyle -h'", L"Para obtener ayuda sobre las opciones tipo 'astyle -h'");
	addPair("Cannot open options file", L"No se puede abrir el archivo de opciones");
	addPair("Cannot open input file", L"No se puede abrir archivo de entrada");
	addPair("Cannot open directory", L"No se puede abrir el directorio");
	addPair("Cannot process the input stream", L"No se puede procesar el flujo de entrada");
	addPair("\nArtistic Style has terminated!", L"\nArtistic Style ha terminado!");
}


#endif	// ASTYLE_LIB

}   // end of namespace astyle

