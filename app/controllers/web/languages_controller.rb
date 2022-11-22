# frozen_string_literal: true

class Web::LanguagesController < Web::ApplicationController
  def show
    @language = Language.find_by!(slug: params[:id])
    @language_version_info = @language.current_version.infos.find_by!(locale: I18n.locale)

    if @language.progress_in_development?
      f('.language_in_development_html', type: :info, values: { language: @language.to_s, link_to_repo: ExternalLinks.source_code_curl }, now: true)
    end

    @current_module_versions = @language.current_module_versions
                                        .includes(:module)
                                        .order(:order)
                                        .eager_load(:lesson_versions)
                                        .joins(:infos)
                                        .merge(Language::Module::Version::Info.with_locale)
                                        .merge(Language::Lesson::Version.includes(:lesson).order(:order))

    @infos_by_module = @language.current_module_infos.with_locale.index_by(&:version_id)
    @infos_by_lesson = @language.current_lesson_infos.with_locale.index_by(&:version_id)

    @finished_lessons_by_id = current_user.finished_lessons_for_language(@language).index_by(&:id)
    @language_member = @language.members.find_by(user: current_user) || Language::MemberFake.new

    @first_lesson = @language.current_lessons.ordered.first
    @next_lesson = current_user.not_finished_lessons_for_language(@language).ordered.first

    @similar_languages = Language.order('RANDOM()').except(@language).limit(4)


    @human_language_title = [@language.current_version.name, @language.learn_as.text].join(' ')

    seo_tags = {
      title: @language_version_info.title,
      description: @language_version_info.seo_description || @language_version_info.description,
      canonical: language_url(@language.slug),
      image_src: view_context.asset_url("#{@language.slug}.png"),
      og: {
        title: @human_language_title,
        type: 'website',
        url: language_url(@language.slug),
        image: view_context.asset_url("#{@language.slug}.png"),
        locale: I18n.locale,
      }
    }
    set_meta_tags seo_tags
  end
end
