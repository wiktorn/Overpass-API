#!/bin/bash

# TODO: split to two files - one with while loop for unattended use
# one for updating to current state - second called by first

DIFF_FILE=/db/diffs/changes.osc

OVERPASS_META=${OVERPASS_META:-no}
OVERPASS_COMPRESSION=${OVERPASS_COMPRESSION:-gz}
OVERPASS_FLUSH_SIZE=${OVERPASS_FLUSH_SIZE:-16}

if [ -z "$OVERPASS_DIFF_URL" ]; then
	echo "No OVERPASS_DIFF_URL set. Skipping update."
	exit 0
fi

(
	set -e
	UPDATE_ARGS=("--flush-size=${OVERPASS_FLUSH_SIZE}")
	if [[ "${OVERPASS_META}" == "attic" ]]; then
		UPDATE_ARGS+=("--keep-attic")
	elif [[ "${OVERPASS_META}" == "yes" ]]; then
		UPDATE_ARGS+=("--meta")
	fi

	if [[ ! -d /db/diffs ]]; then
		mkdir /db/diffs
	fi

	if /app/bin/dispatcher --show-dir | grep -q File_Error; then
		UPDATE_ARGS+=("--db-dir=/db/db")
	fi

	if [[ "${USE_OAUTH_COOKIE_CLIENT}" = "yes" ]]; then
		/app/venv/bin/python /app/bin/oauth_cookie_client.py -o /db/cookie.jar -s /secrets/oauth-settings.json --format netscape
	fi

	while true; do
		# if DIFF_FILE doesn't exit, try fetch new data
		if [[ ! -e ${DIFF_FILE} ]]; then
			# if /db/replicate_id exists, do not pass $1 arg (which could contain -O arg pointing to planet file
			if [[ -s /db/replicate_id ]]; then
				cp -f /db/replicate_id /db/replicate_id.backup
				set +e
				/app/venv/bin/pyosmium-get-changes -vvv --cookie /db/cookie.jar --server "${OVERPASS_DIFF_URL}" -o "${DIFF_FILE}" -f /db/replicate_id
				OSMIUM_STATUS=$?
				set -e
			else
				set +e
				/app/venv/bin/pyosmium-get-changes -vvv "$@" --cookie /db/cookie.jar --server "${OVERPASS_DIFF_URL}" -o "${DIFF_FILE}" -f /db/replicate_id
				OSMIUM_STATUS=$?
				set -e
			fi
		else
			echo "/db/diffs/changes.osm exists. Trying to apply again."
		fi

		# if DIFF_FILE is non-empty, try to process it
		if [[ -s ${DIFF_FILE} ]]; then
			VERSION=$(osmium fileinfo -e -g data.timestamp.last "${DIFF_FILE}" || (cp -f /db/replicate_id.backup /db/replicate_id && echo "Broken file" && cat "${DIFF_FILE}" && rm -f "${DIFF_FILE}" && exit 1))
			if [[ -n "${VERSION// /}" ]]; then
				echo /app/bin/update_from_dir --osc-dir="$(dirname ${DIFF_FILE})" --version="${VERSION}" "${UPDATE_ARGS[@]}"
				/app/bin/update_from_dir --osc-dir="$(dirname ${DIFF_FILE})" --version="${VERSION}" "${UPDATE_ARGS[@]}"
			else
				echo "Empty version, skipping file"
				cat "${DIFF_FILE}"
			fi
		fi

		# processed successfuly, remove
		rm "${DIFF_FILE}"

		if [[ "${OSMIUM_STATUS}" -eq 3 ]]; then
			echo "Update finished with status code: ${OSMIUM_STATUS}"
			break
		else
			echo "There are still some updates remaining"
			continue
		fi
		break
	done
) 2>&1 | tee -a /db/changes.log
