# LIBRARIES

if(!'pacman' %in% rownames(installed.packages())) {
	install.packages(pacman)
}

pacman::p_load(dplyr, readr, tidyr, stringr, magrittr, purrr, rlist, httr, jsonlite, pdftools, rvest, qdap)


# KEYS

source('secret/config.py')


# FUNCTIONS

GetChan <- function(channel, token) {

	contents.req <-
		str_c('https://api.are.na/v2/channels/', channel, '/contents') %>%
		GET(add_headers(Authorization = str_c('bearer ', token))) %>%
		content(type = 'text', encoding = 'UTF-8') %>%
		fromJSON %>%
		.$contents

	contents <- contents.req[names(contents.req) %in% c('id', 'title', 'slug', 'class')]

	contents$user_id         <- contents.req$user$id
	contents$user_name       <- contents.req$user$username
	contents$user_slug       <- contents.req$user$slug
	contents$user_avatar     <- contents.req$user$avatar_image$display

	contents$attachment_name <- contents.req$attachment$file_name
	contents$attachment_type <- contents.req$attachment$content_type
	contents$attachment_url  <- contents.req$attachment$url

	contents$image_name      <- contents.req$image$filename
	contents$image_type      <- contents.req$image$content_type
	contents$image_url       <- contents.req$image$large$url

	contents$url             <- contents.req$source$url

	contents %>% as_data_frame

}


SaveTxt <- function(file.name, txt) {

	sink(str_c('txt/', file.name))
		cat(txt)
	sink()

}

CleanUp <- function(strings) {

	strings %>%
	unlist %>%
	list.filter(nchar(.) > 2) %>%
	strip %>%
	gsub(' +', ' ', .) %>%
	gsub('^\\s+|\\s+$', '', .) %>%
	clean %>%
	str_trim %>%
	str_c(collapse = '\n')

}


# MAIN

message(str_c('- querying Are.na channel: ', ARCHIVE_CHAN))

channel <- GetChan(channel = ARCHIVE_CHAN, token = ARENA_TOKEN)


# ATTACHMENTS

message(str_c('- parsing pdfs'))

attachments <-
	channel %>%
	filter(class == 'Attachment') %>%
	filter(attachment_type == 'application/pdf')

map2(attachments$attachment_url, str_c('media/', attachments$attachment_name), ~ { download.file(.x, .y, mode = 'wb') })

attachments.parse <-
	str_c('media/', attachments$attachment_name) %>%
	map( ~ {
		pdf_text(.x) %>%
		CleanUp
	})

map2(str_c(attachments$id, '.txt'), attachments.parse, ~ { SaveTxt(.x, .y) })


# RENDERING PDF IMAGES
# bitmap <- pdf_render_page(attachment_name, page = 1)
# png::writePNG(bitmap, "page.png")


# LINKS

message(str_c('- parsing links'))

links <- channel %>% filter(class == 'Link')

links.parse <-
	links$url %>%
	map( ~ {
		read_html(.x) %>%
		html_nodes('body :not(script)') %>%
		html_text() %>%
		CleanUp
	})

map2(str_c(links$id, '.txt'), links.parse, ~ { SaveTxt(.x, .y) })


message('[ done ]')





