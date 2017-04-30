
library(wordVectors)
library(stringdist)

source('pulldown.R')

corpus <- paste(c(links.parse, attachments.parse), collapse='\n')

sink('corpus.txt')
	cat(corpus)
sink()


names(links.parse) <- links$id
names(attachments.parse) <- attachments$id

txt.parse <- c(links.parse, attachments.parse)

#PrepWord2vec('corpus', 'corpus.txt', lowercase = TRUE)

model <- train_word2vec('corpus.txt', output = 'corpus_vectors.bin', threads = 3, vectors = 100, window = 12)

# model <- read.vectors("corpus_vectors.bin")  # read-in previously trained model

highlights <-
	txt.parse %>%
	map( ~ {

		words <-
			str_split(.x, ' ') %>%
			.[[1]] %>%
			list.filter(nchar(.) > 4 & nchar(.) < 7)

		words[duplicated(words)] %>% unique
	})


combi <-
	t(combn(c(names(highlights), names(highlights)), 2)) %>%
	as_data_frame %>%
	set_names(c('a', 'b')) %>%
	filter(a != b)

alike <-
	map2(combi$a, combi$b, ~ {

		a = .x
		b = .y

		# print(a)

		# print(class(highlights[a][[1]]))

		sim <- cosineSimilarity(
			model[[highlights[a][[1]], average = TRUE]],
			model[[highlights[b][[1]], average = TRUE]]
		)

		if(is.null(sim)) {
			NA
		} else {
			sim
		}

	})

adj <-
combi %>%
mutate(weight = unlist(alike)) %>%
unique %>%
filter(!is.nan(weight)) %>%
spread(b, weight) %>%
rename(id = a)

write_csv(adj, 'adj.csv')




