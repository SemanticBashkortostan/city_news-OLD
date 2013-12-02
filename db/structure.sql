--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: active_admin_comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE active_admin_comments (
    id integer NOT NULL,
    resource_id character varying(255) NOT NULL,
    resource_type character varying(255) NOT NULL,
    author_id integer,
    author_type character varying(255),
    body text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    namespace character varying(255)
);


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE active_admin_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE active_admin_comments_id_seq OWNED BY active_admin_comments.id;


--
-- Name: classifier_text_class_feature_properties; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE classifier_text_class_feature_properties (
    id integer NOT NULL,
    classifier_id integer,
    text_class_feature_id integer,
    feature_count integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: classifier_text_class_feature_properties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE classifier_text_class_feature_properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classifier_text_class_feature_properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE classifier_text_class_feature_properties_id_seq OWNED BY classifier_text_class_feature_properties.id;


--
-- Name: classifiers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE classifiers (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    parameters hstore
);


--
-- Name: classifiers_feeds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE classifiers_feeds (
    id integer NOT NULL,
    classifier_id integer,
    feed_id integer
);


--
-- Name: classifiers_feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE classifiers_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classifiers_feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE classifiers_feeds_id_seq OWNED BY classifiers_feeds.id;


--
-- Name: classifiers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE classifiers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: classifiers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE classifiers_id_seq OWNED BY classifiers.id;


--
-- Name: docs_counts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE docs_counts (
    id integer NOT NULL,
    classifier_id integer,
    text_class_id integer,
    docs_count integer DEFAULT 0
);


--
-- Name: docs_counts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE docs_counts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: docs_counts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE docs_counts_id_seq OWNED BY docs_counts.id;


--
-- Name: features; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE features (
    id integer NOT NULL,
    token character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE features_id_seq OWNED BY features.id;


--
-- Name: feed_classified_infos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feed_classified_infos (
    id integer NOT NULL,
    feed_id integer,
    classifier_id integer,
    text_class_id integer,
    to_train boolean,
    score double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: feed_classified_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feed_classified_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feed_classified_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feed_classified_infos_id_seq OWNED BY feed_classified_infos.id;


--
-- Name: feed_sources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feed_sources (
    id integer NOT NULL,
    text_class_id integer,
    url character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    extractable_main_content boolean,
    active boolean DEFAULT true
);


--
-- Name: feed_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feed_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feed_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feed_sources_id_seq OWNED BY feed_sources.id;


--
-- Name: feedbacks_feedbacks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feedbacks_feedbacks (
    id integer NOT NULL,
    topic character varying(255),
    text text,
    email character varying(255),
    url character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: feedbacks_feedbacks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feedbacks_feedbacks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedbacks_feedbacks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feedbacks_feedbacks_id_seq OWNED BY feedbacks_feedbacks.id;


--
-- Name: feeds; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feeds (
    id integer NOT NULL,
    title character varying(255),
    url text,
    summary text,
    published_at timestamp without time zone,
    text_class_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    similar_score double precision,
    ancestry character varying(255),
    feed_source_id integer,
    main_html_content text
);


--
-- Name: feeds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feeds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feeds_id_seq OWNED BY feeds.id;


--
-- Name: rb7_news; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE rb7_news (
    id integer NOT NULL,
    nid integer,
    title character varying(255),
    annotation character varying(500),
    text text,
    source character varying(255),
    created integer,
    changed integer,
    tid integer
);


--
-- Name: rb7_news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rb7_news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rb7_news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rb7_news_id_seq OWNED BY rb7_news.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles (
    id integer NOT NULL,
    name character varying(255),
    resource_id integer,
    resource_type character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_id integer,
    taggable_type character varying(255),
    tagger_id integer,
    tagger_type character varying(255),
    context character varying(128),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE taggings_id_seq OWNED BY taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- Name: text_class_features; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE text_class_features (
    id integer NOT NULL,
    text_class_id integer,
    feature_id integer,
    feature_count integer
);


--
-- Name: text_class_features_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE text_class_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: text_class_features_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE text_class_features_id_seq OWNED BY text_class_features.id;


--
-- Name: text_classes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE text_classes (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    eng_name character varying(255),
    prepositional_name character varying(255)
);


--
-- Name: text_classes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE text_classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: text_classes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE text_classes_id_seq OWNED BY text_classes.id;


--
-- Name: text_classes_vocabulary_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE text_classes_vocabulary_entries (
    id integer NOT NULL,
    text_class_id integer,
    vocabulary_entry_id integer
);


--
-- Name: text_classes_vocabulary_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE text_classes_vocabulary_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: text_classes_vocabulary_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE text_classes_vocabulary_entries_id_seq OWNED BY text_classes_vocabulary_entries.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying(255)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users_roles (
    user_id integer,
    role_id integer
);


--
-- Name: vocabulary_entries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vocabulary_entries (
    id integer NOT NULL,
    token character varying(255),
    regexp_rule character varying(255),
    state integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    truly_city boolean DEFAULT false
);


--
-- Name: vocabulary_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE vocabulary_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vocabulary_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE vocabulary_entries_id_seq OWNED BY vocabulary_entries.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY active_admin_comments ALTER COLUMN id SET DEFAULT nextval('active_admin_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY classifier_text_class_feature_properties ALTER COLUMN id SET DEFAULT nextval('classifier_text_class_feature_properties_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY classifiers ALTER COLUMN id SET DEFAULT nextval('classifiers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY classifiers_feeds ALTER COLUMN id SET DEFAULT nextval('classifiers_feeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY docs_counts ALTER COLUMN id SET DEFAULT nextval('docs_counts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY features ALTER COLUMN id SET DEFAULT nextval('features_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_classified_infos ALTER COLUMN id SET DEFAULT nextval('feed_classified_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_sources ALTER COLUMN id SET DEFAULT nextval('feed_sources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feedbacks_feedbacks ALTER COLUMN id SET DEFAULT nextval('feedbacks_feedbacks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feeds ALTER COLUMN id SET DEFAULT nextval('feeds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rb7_news ALTER COLUMN id SET DEFAULT nextval('rb7_news_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY taggings ALTER COLUMN id SET DEFAULT nextval('taggings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY text_class_features ALTER COLUMN id SET DEFAULT nextval('text_class_features_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY text_classes ALTER COLUMN id SET DEFAULT nextval('text_classes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY text_classes_vocabulary_entries ALTER COLUMN id SET DEFAULT nextval('text_classes_vocabulary_entries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY vocabulary_entries ALTER COLUMN id SET DEFAULT nextval('vocabulary_entries_id_seq'::regclass);


--
-- Name: active_admin_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY active_admin_comments
    ADD CONSTRAINT active_admin_comments_pkey PRIMARY KEY (id);


--
-- Name: classifier_text_class_feature_properties_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY classifier_text_class_feature_properties
    ADD CONSTRAINT classifier_text_class_feature_properties_pkey PRIMARY KEY (id);


--
-- Name: classifiers_feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY classifiers_feeds
    ADD CONSTRAINT classifiers_feeds_pkey PRIMARY KEY (id);


--
-- Name: classifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY classifiers
    ADD CONSTRAINT classifiers_pkey PRIMARY KEY (id);


--
-- Name: docs_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY docs_counts
    ADD CONSTRAINT docs_counts_pkey PRIMARY KEY (id);


--
-- Name: features_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY features
    ADD CONSTRAINT features_pkey PRIMARY KEY (id);


--
-- Name: feed_classified_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_classified_infos
    ADD CONSTRAINT feed_classified_infos_pkey PRIMARY KEY (id);


--
-- Name: feed_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_sources
    ADD CONSTRAINT feed_sources_pkey PRIMARY KEY (id);


--
-- Name: feedbacks_feedbacks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feedbacks_feedbacks
    ADD CONSTRAINT feedbacks_feedbacks_pkey PRIMARY KEY (id);


--
-- Name: feeds_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feeds
    ADD CONSTRAINT feeds_pkey PRIMARY KEY (id);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: text_class_features_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY text_class_features
    ADD CONSTRAINT text_class_features_pkey PRIMARY KEY (id);


--
-- Name: text_classes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY text_classes
    ADD CONSTRAINT text_classes_pkey PRIMARY KEY (id);


--
-- Name: text_classes_vocabulary_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY text_classes_vocabulary_entries
    ADD CONSTRAINT text_classes_vocabulary_entries_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vocabulary_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vocabulary_entries
    ADD CONSTRAINT vocabulary_entries_pkey PRIMARY KEY (id);


--
-- Name: classifier_tcf_prop_ind; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX classifier_tcf_prop_ind ON classifier_text_class_feature_properties USING btree (classifier_id, text_class_feature_id);


--
-- Name: index_active_admin_comments_on_author_type_and_author_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_active_admin_comments_on_author_type_and_author_id ON active_admin_comments USING btree (author_type, author_id);


--
-- Name: index_active_admin_comments_on_namespace; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_active_admin_comments_on_namespace ON active_admin_comments USING btree (namespace);


--
-- Name: index_admin_notes_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_admin_notes_on_resource_type_and_resource_id ON active_admin_comments USING btree (resource_type, resource_id);


--
-- Name: index_classifiers_feeds_on_classifier_id_and_feed_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_classifiers_feeds_on_classifier_id_and_feed_id ON classifiers_feeds USING btree (classifier_id, feed_id);


--
-- Name: index_docs_counts_on_classifier_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_docs_counts_on_classifier_id ON docs_counts USING btree (classifier_id);


--
-- Name: index_docs_counts_on_text_class_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_docs_counts_on_text_class_id ON docs_counts USING btree (text_class_id);


--
-- Name: index_feed_classified_infos_on_feed_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_classified_infos_on_feed_id ON feed_classified_infos USING btree (feed_id);


--
-- Name: index_feed_classified_infos_on_feed_id_and_classifier_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_classified_infos_on_feed_id_and_classifier_id ON feed_classified_infos USING btree (feed_id, classifier_id);


--
-- Name: index_feed_sources_on_active; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_sources_on_active ON feed_sources USING btree (active);


--
-- Name: index_feed_sources_on_extractable_main_content; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_sources_on_extractable_main_content ON feed_sources USING btree (extractable_main_content);


--
-- Name: index_feed_sources_on_text_class_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_sources_on_text_class_id ON feed_sources USING btree (text_class_id);


--
-- Name: index_feed_sources_on_url; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feed_sources_on_url ON feed_sources USING btree (url);


--
-- Name: index_feeds_on_ancestry; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_ancestry ON feeds USING btree (ancestry);


--
-- Name: index_feeds_on_feed_source_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_feeds_on_feed_source_id ON feeds USING btree (feed_source_id);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_on_name ON roles USING btree (name);


--
-- Name: index_roles_on_name_and_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_roles_on_name_and_resource_type_and_resource_id ON roles USING btree (name, resource_type, resource_id);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_taggings_on_tag_id ON taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id_and_taggable_type_and_context; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_taggings_on_taggable_id_and_taggable_type_and_context ON taggings USING btree (taggable_id, taggable_type, context);


--
-- Name: index_text_class_features_on_feature_id_and_text_class_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_text_class_features_on_feature_id_and_text_class_id ON text_class_features USING btree (feature_id, text_class_id);


--
-- Name: index_text_class_features_on_text_class_id_and_feature_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_text_class_features_on_text_class_id_and_feature_id ON text_class_features USING btree (text_class_id, feature_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_roles_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_roles_on_user_id_and_role_id ON users_roles USING btree (user_id, role_id);


--
-- Name: index_vocabulary_entries_on_state_and_regexp_rule; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_vocabulary_entries_on_state_and_regexp_rule ON vocabulary_entries USING btree (state, regexp_rule);


--
-- Name: index_vocabulary_entries_on_state_and_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_vocabulary_entries_on_state_and_token ON vocabulary_entries USING btree (state, token);


--
-- Name: index_vocabulary_entries_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_vocabulary_entries_on_token ON vocabulary_entries USING btree (token);


--
-- Name: uniq_nid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX uniq_nid ON rb7_news USING btree (nid);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: voc_entry_tc_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX voc_entry_tc_index ON text_classes_vocabulary_entries USING btree (text_class_id, vocabulary_entry_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20121204064421');

INSERT INTO schema_migrations (version) VALUES ('20121204064431');

INSERT INTO schema_migrations (version) VALUES ('20121204064451');

INSERT INTO schema_migrations (version) VALUES ('20121205160206');

INSERT INTO schema_migrations (version) VALUES ('20121205160207');

INSERT INTO schema_migrations (version) VALUES ('20121205161739');

INSERT INTO schema_migrations (version) VALUES ('20121205162309');

INSERT INTO schema_migrations (version) VALUES ('20121205162814');

INSERT INTO schema_migrations (version) VALUES ('20121205162849');

INSERT INTO schema_migrations (version) VALUES ('20121206185308');

INSERT INTO schema_migrations (version) VALUES ('20121207052127');

INSERT INTO schema_migrations (version) VALUES ('20121225173359');

INSERT INTO schema_migrations (version) VALUES ('20121225173658');

INSERT INTO schema_migrations (version) VALUES ('20130117051518');

INSERT INTO schema_migrations (version) VALUES ('20130122131935');

INSERT INTO schema_migrations (version) VALUES ('20130126134123');

INSERT INTO schema_migrations (version) VALUES ('20130224152923');

INSERT INTO schema_migrations (version) VALUES ('20130224161223');

INSERT INTO schema_migrations (version) VALUES ('20130226074302');

INSERT INTO schema_migrations (version) VALUES ('20130226105149');

INSERT INTO schema_migrations (version) VALUES ('20130304064307');

INSERT INTO schema_migrations (version) VALUES ('20130305071745');

INSERT INTO schema_migrations (version) VALUES ('20130416131140');

INSERT INTO schema_migrations (version) VALUES ('20130416131219');

INSERT INTO schema_migrations (version) VALUES ('20130422115114');

INSERT INTO schema_migrations (version) VALUES ('20130422122127');

INSERT INTO schema_migrations (version) VALUES ('20130423051244');

INSERT INTO schema_migrations (version) VALUES ('20130426063801');

INSERT INTO schema_migrations (version) VALUES ('20130428085308');

INSERT INTO schema_migrations (version) VALUES ('20131011184441');

INSERT INTO schema_migrations (version) VALUES ('20131130090159');

INSERT INTO schema_migrations (version) VALUES ('20131130094218');

INSERT INTO schema_migrations (version) VALUES ('20131202180430');

INSERT INTO schema_migrations (version) VALUES ('20131202183320');